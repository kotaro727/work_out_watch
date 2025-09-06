import Foundation
import os.log

// HealthKit機能を無効化した代替実装
@MainActor
class HealthKitManagerDisabled: ObservableObject {
    private static let logger = Logger(subsystem: "com.workout.app", category: "HealthKit")
    
    @Published var isAuthorized = false
    @Published var authorizationStatus = "notDetermined"
    
    init() {
        Self.logger.info("HealthKit manager initialized (disabled mode)")
    }
    
    func checkAuthorizationStatus() {
        // No-op for disabled version
        Self.logger.info("HealthKit authorization check skipped (disabled)")
    }
    
    func requestAuthorization() async throws {
        Self.logger.info("HealthKit authorization request skipped (disabled)")
        // No actual authorization request
    }
    
    func saveWorkout(session: WorkoutSession) async throws -> String {
        Self.logger.info("HealthKit workout save skipped (disabled)")
        return UUID().uuidString // Return dummy ID
    }
    
    func fetchRecentWorkouts(limit: Int = 10) async throws -> [String] {
        Self.logger.info("HealthKit workout fetch skipped (disabled)")
        return [] // Return empty array
    }
}

// HealthKit関連エラー（ダミー実装）
enum HealthKitErrorDisabled: LocalizedError {
    case disabled
    
    var errorDescription: String? {
        return "HealthKit is disabled in this build"
    }
}