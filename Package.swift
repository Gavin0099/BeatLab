// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BeatLabCore",
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "BeatLabCore", targets: ["BeatLabCore"]),
        .library(name: "BeatLabDSP", targets: ["BeatLabDSP"])
    ],
    targets: [
        .target(name: "BeatLabDSP", linkerSettings: [.linkedLibrary("m", .when(platforms: [.linux]))]),
        .target(name: "BeatLabCore", resources: [.process("Resources")]),
        .testTarget(name: "BeatLabCoreTests", dependencies: ["BeatLabCore", "BeatLabDSP"])
    ]
)
