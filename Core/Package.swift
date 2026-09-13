// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GoalieTrackerCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "GoalieTrackerCore",
            targets: ["GoalieTrackerCore"]
        )
    ],
    targets: [
        .target(
            name: "GoalieTrackerCore",
            path: "Sources/GoalieTrackerCore"
        ),
        .testTarget(
            name: "GoalieTrackerCoreTests",
            dependencies: ["GoalieTrackerCore"],
            path: "Tests/GoalieTrackerCoreTests"
        )
    ]
)
