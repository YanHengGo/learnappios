// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LearnModules",
    platforms: [.iOS(.v17)],
    products: [
        // Core
        .library(name: "CoreModel",     targets: ["CoreModel"]),
        .library(name: "CoreCommon",    targets: ["CoreCommon"]),
        .library(name: "CoreNetwork",   targets: ["CoreNetwork"]),
        .library(name: "CoreDataStore", targets: ["CoreDataStore"]),
        .library(name: "CoreDomain",    targets: ["CoreDomain"]),
        .library(name: "CoreData",      targets: ["CoreData"]),
        .library(name: "CoreUI",        targets: ["CoreUI"]),
        // Features
        .library(name: "FeatureSplash",   targets: ["FeatureSplash"]),
        .library(name: "FeatureAuth",     targets: ["FeatureAuth"]),
        .library(name: "FeatureChildren", targets: ["FeatureChildren"]),
        .library(name: "FeatureDaily",    targets: ["FeatureDaily"]),
        .library(name: "FeatureTasks",    targets: ["FeatureTasks"]),
        .library(name: "FeatureSummary",  targets: ["FeatureSummary"]),
        .library(name: "FeatureHome",     targets: ["FeatureHome"]),
    ],
    targets: [
        // ── Core ─────────────────────────────────────────────────────
        .target(name: "CoreModel"),
        .target(name: "CoreCommon"),
        .target(
            name: "CoreNetwork",
            dependencies: ["CoreModel", "CoreCommon"]
        ),
        .target(
            name: "CoreDataStore",
            linkerSettings: [.linkedFramework("Security")]
        ),
        .target(
            name: "CoreDomain",
            dependencies: ["CoreModel", "CoreCommon"]
        ),
        .target(
            name: "CoreData",
            dependencies: ["CoreDomain", "CoreNetwork", "CoreDataStore"]
        ),
        .target(
            name: "CoreUI",
            dependencies: ["CoreModel"]
        ),
        // ── Features ─────────────────────────────────────────────────
        .target(name: "FeatureSplash",   dependencies: ["CoreDomain", "CoreUI"]),
        .target(name: "FeatureAuth",     dependencies: ["CoreDomain", "CoreCommon", "CoreUI"]),
        .target(name: "FeatureChildren", dependencies: ["CoreDomain", "CoreCommon", "CoreUI"]),
        .target(name: "FeatureDaily",    dependencies: ["CoreDomain", "CoreUI"]),
        .target(name: "FeatureTasks",    dependencies: ["CoreDomain", "CoreUI"]),
        .target(
            name: "FeatureSummary",
            dependencies: ["CoreDomain", "CoreUI", "FeatureDaily"]
        ),
        .target(
            name: "FeatureHome",
            dependencies: [
                "CoreDomain", "CoreUI",
                "FeatureDaily", "FeatureTasks", "FeatureSummary",
            ]
        ),
        // ── Tests ────────────────────────────────────────────────────
        .testTarget(name: "CoreNetworkTests",  dependencies: ["CoreNetwork"]),
        .testTarget(name: "CoreDataTests",     dependencies: ["CoreData"]),
        .testTarget(name: "CoreDomainTests",   dependencies: ["CoreDomain"]),
        .testTarget(name: "FeatureAuthTests",  dependencies: ["FeatureAuth"]),
    ]
)
