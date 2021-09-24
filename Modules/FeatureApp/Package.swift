// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "FeatureApp",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "FeatureApp", targets: ["FeatureAppUI"])
    ],
    dependencies: [
        .package(
            name: "CombineExt",
            url: "https://github.com/CombineCommunity/CombineExt.git",
            from: "1.5.0"
        ),
        .package(
            name: "RxSwift",
            url: "https://github.com/ReactiveX/RxSwift.git",
            from: "5.1.3"
        ),
        .package(
            name: "DIKit",
            url: "https://github.com/jackpooleybc/DIKit.git",
            .branch("safe-property-wrappers")
        ),
        .package(
            name: "swift-composable-architecture",
            url: "https://github.com/pointfreeco/swift-composable-architecture",
            from: "0.18.0"
        ),
        .package(path: "../Analytics"),
        .package(path: "../CryptoAssets"),
        .package(path: "../FeatureDashboard"),
        .package(path: "../FeatureDebug"),
        .package(path: "../FeatureAuthentication"),
        .package(path: "../FeatureSettings"),
        .package(path: "../Localization"),
        .package(path: "../Platform"),
        .package(path: "../Tool"),
        .package(path: "../WalletPayload"),
        .package(path: "../RemoteNotifications")
    ],
    targets: [
        .target(
            name: "FeatureAppUI",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "BitcoinChainKit", package: "CryptoAssets"),
                .product(name: "AnalyticsKit", package: "Analytics"),
                .product(name: "FeatureDebugUI", package: "FeatureDebug"),
                .product(name: "FeatureDashboardUI", package: "FeatureDashboard"),
                .product(name: "FeatureAuthenticationDomain", package: "FeatureAuthentication"),
                .product(name: "FeatureAuthenticationUI", package: "FeatureAuthentication"),
                .product(name: "FeatureSettingsDomain", package: "FeatureSettings"),
                .product(name: "RemoteNotificationsKit", package: "RemoteNotifications"),
                .product(name: "Localization", package: "Localization"),
                .product(name: "PlatformKit", package: "Platform"),
                .product(name: "PlatformUIKit", package: "Platform"),
                .product(name: "RxCocoa", package: "RxSwift"),
                .product(name: "RxRelay", package: "RxSwift"),
                .product(name: "RxSwift", package: "RxSwift"),
                .product(name: "ToolKit", package: "Tool")
            ]
        )
    ]
)