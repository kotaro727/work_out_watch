import Foundation
import HealthKit
import os.log

@MainActor
class HealthKitManager: ObservableObject {
    private static let logger = Logger(subsystem: "com.workout.app", category: "HealthKit")
    
    private let healthStore = HKHealthStore()
    @Published var isAuthorized = false
    @Published var authorizationStatus: HKAuthorizationStatus = .notDetermined
    
    // HealthKitで読み書きするデータタイプ
    private let readTypes: Set<HKObjectType> = [
        HKObjectType.workoutType(),
        HKObjectType.quantityType(forIdentifier: .bodyMass)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
    ]
    
    private let writeTypes: Set<HKSampleType> = [
        HKObjectType.workoutType(),
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
    ]
    
    init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else {
            Self.logger.warning("HealthKit is not available on this device")
            return
        }
        
        authorizationStatus = healthStore.authorizationStatus(for: HKObjectType.workoutType())
        isAuthorized = (authorizationStatus == .sharingAuthorized)
    }
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
            await MainActor.run {
                checkAuthorizationStatus()
            }
            Self.logger.info("HealthKit authorization completed")
        } catch {
            Self.logger.error("HealthKit authorization failed: \(error)")
            throw HealthKitError.authorizationFailed(error)
        }
    }
    
    // MARK: - Workout Management
    
    func saveWorkout(session: WorkoutSession) async throws -> String {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .traditionalStrengthTraining
        workoutConfiguration.locationType = .indoor
        
        let totalEnergyBurned: HKQuantity?
        if session.totalCalories > 0 {
            totalEnergyBurned = HKQuantity(unit: .kilocalorie(), doubleValue: session.totalCalories)
        } else {
            totalEnergyBurned = nil
        }
        
        let workout = HKWorkout(
            activityType: workoutConfiguration.activityType,
            start: session.startTime ?? Date(),
            end: session.endTime ?? Date(),
            duration: session.duration,
            totalEnergyBurned: totalEnergyBurned,
            totalDistance: nil,
            metadata: createWorkoutMetadata(from: session)
        )
        
        do {
            try await healthStore.save(workout)
            Self.logger.info("Workout saved to HealthKit: \(workout.uuid)")
            
            // WorkoutSetをHKQuantitySampleとして保存
            try await saveWorkoutSets(session.workoutSets?.allObjects as? [WorkoutSet] ?? [], for: workout)
            
            return workout.uuid.uuidString
        } catch {
            Self.logger.error("Failed to save workout to HealthKit: \(error)")
            throw HealthKitError.saveFailed(error)
        }
    }
    
    private func saveWorkoutSets(_ sets: [WorkoutSet], for workout: HKWorkout) async throws {
        var samples: [HKSample] = []
        
        for set in sets {
            // 重量データをHKQuantitySampleとして作成
            if let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
                let weightQuantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: set.weight)
                let weightSample = HKQuantitySample(
                    type: weightType,
                    quantity: weightQuantity,
                    start: set.createdAt ?? Date(),
                    end: set.updatedAt ?? Date(),
                    metadata: [
                        HKMetadataKeyWorkoutBrandName: set.exercise?.name ?? "Unknown",
                        "SetNumber": set.setNumber,
                        "Repetitions": set.repetitions
                    ]
                )
                samples.append(weightSample)
            }
        }
        
        if !samples.isEmpty {
            try await healthStore.save(samples)
            Self.logger.info("Saved \(samples.count) workout samples to HealthKit")
        }
    }
    
    private func createWorkoutMetadata(from session: WorkoutSession) -> [String: Any] {
        var metadata: [String: Any] = [:]
        
        if let notes = session.notes {
            metadata[HKMetadataKeyWorkoutBrandName] = notes
        }
        
        // セット数とエクササイズ情報を追加
        if let sets = session.workoutSets?.allObjects as? [WorkoutSet] {
            let exerciseNames = Array(Set(sets.compactMap { $0.exercise?.name }))
            metadata["ExerciseTypes"] = exerciseNames.joined(separator: ", ")
            metadata["TotalSets"] = sets.count
        }
        
        return metadata
    }
    
    // MARK: - Data Retrieval
    
    func fetchRecentWorkouts(limit: Int = 10) async throws -> [HKWorkout] {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }
        
        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let workoutQuery = HKSampleQuery(
                sampleType: workoutType,
                predicate: HKQuery.predicateForWorkouts(with: .traditionalStrengthTraining),
                limit: limit,
                sortDescriptors: [sortDescriptor]
            ) { query, samples, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                } else {
                    let workouts = samples as? [HKWorkout] ?? []
                    continuation.resume(returning: workouts)
                }
            }
            
            healthStore.execute(workoutQuery)
        }
    }
}

// MARK: - Extensions

extension WorkoutSession {
    var duration: TimeInterval {
        guard let start = startTime, let end = endTime else { return 0 }
        return end.timeIntervalSince(start)
    }
}

// MARK: - Error Types

enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case authorizationFailed(Error)
    case saveFailed(Error)
    case queryFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .notAuthorized:
            return "HealthKit access not authorized"
        case .authorizationFailed(let error):
            return "HealthKit authorization failed: \(error.localizedDescription)"
        case .saveFailed(let error):
            return "Failed to save to HealthKit: \(error.localizedDescription)"
        case .queryFailed(let error):
            return "HealthKit query failed: \(error.localizedDescription)"
        }
    }
}