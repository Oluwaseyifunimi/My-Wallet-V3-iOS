// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import Combine
import FeatureAuthenticationDomain
import Foundation
import NetworkKit
import ToolKit

public protocol IterableServiceAPI {
    func updateToken(_ token: String) -> AnyPublisher<Void, NabuNetworkError>
}

final class IterableService: IterableServiceAPI {
    // MARK: - Types

    struct UpdateTokenRequest: Encodable {
        struct Device: Encodable {

            enum Platform: String, Encodable {
                case sandbox = "APNS_SANDBOX"
                case production = "APNS"

                static var currentPlatform: Platform {
                    #if DEBUG
                    return .sandbox
                    #else
                    return .production
                    #endif
                }
            }

            let applicationName: String?
            let token: String
            let platform: Platform
        }

        let email: String
        let device: Device

        init(
            email: String,
            token: String
        ) {
            self.email = email
            self.device = Device(
                applicationName: Bundle.main.bundleIdentifier,
                token: token,
                platform: .currentPlatform
            )
        }
    }

    // MARK: - Properties

    private static let path = ["users", "registerDeviceToken"]

    private let app: AppProtocol
    private let networkAdapter: NetworkAdapterAPI
    private let requestBuilder: RequestBuilder

    // MARK: - Setup

    init(
        app: AppProtocol,
        networkAdapter: NetworkAdapterAPI,
        requestBuilder: RequestBuilder
    ) {
        self.app = app
        self.networkAdapter = networkAdapter
        self.requestBuilder = requestBuilder
    }

    func updateToken(_ token: String) -> AnyPublisher<Void, NabuNetworkError> {
        app
            .state
            .publisher(for: blockchain.user.email.address)
            .decode()
            .compactMap(\.value)
            .filter(\.isNotEmpty)
            .setFailureType(to: NabuNetworkError.self)
            .flatMapLatest { [weak self] email -> AnyPublisher<Void, NabuNetworkError> in
                guard let self else {
                    return .just(())
                }
                let request = self.requestBuilder.post(
                    path: Self.path,
                    body: try? UpdateTokenRequest(email: email, token: token).encode()
                )!
                return self.networkAdapter.perform(request: request)
            }
            .eraseToAnyPublisher()
    }
}
