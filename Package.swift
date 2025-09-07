// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WorkoutApp",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10)
    ],
    products: [
        .library(
            name: "WorkoutApp",
            targets: ["WorkoutApp"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
    ],
    targets: [
        .target(
            name: "WorkoutApp",
            dependencies: [],
            path: "Sources/WorkoutApp",
            resources: [
                .process("WorkoutDataModel.xcdatamodeld")
            ]
        ),
        .testTarget(
            name: "WorkoutAppTests",
            dependencies: ["WorkoutApp"]
        )
    ]
)