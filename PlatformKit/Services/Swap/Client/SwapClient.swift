//
//  SwapClient.swift
//  PlatformKit
//
//  Created by Alex McGregor on 4/24/20.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import NetworkKit
import RxSwift

public protocol SwapActivityClientAPI {
    // TODO: Fetch a single activity from an order ID
    func fetchActivity(from date: Date,
                       fiatCurrency: String,
                       cryptoCurrency: CryptoCurrency,
                       limit: Int,
                       token: String) -> Single<[SwapActivityItemEvent]>
    
    func fetchActivity(from date: Date,
                       fiatCurrency: String,
                       token: String) -> Single<[SwapActivityItemEvent]>
}

public typealias SwapClientAPI = SwapActivityClientAPI

public final class SwapClient: SwapClientAPI {
    
    private enum Parameter {
        static let before = "before"
        static let fiatCurrency = "userFiatCurrency"
        static let cryptoCurrency = "currency"
        static let limit = "limit"
    }
    
    private enum Path {
        static let activity = ["trades"]
    }
    
    // MARK: - Properties
    
    private let requestBuilder: RequestBuilder
    private let communicator: NetworkCommunicatorAPI
    
    // MARK: - Setup
    
    public init(dependencies: Network.Dependencies = .retail) {
        self.communicator = dependencies.communicator
        self.requestBuilder = RequestBuilder(networkConfig: dependencies.blockchainAPIConfig)
    }
    
    // MARK: - SwapActivityClientAPI
    
    public func fetchActivity(from date: Date,
                              fiatCurrency: String,
                              cryptoCurrency: CryptoCurrency,
                              limit: Int,
                              token: String) -> Single<[SwapActivityItemEvent]> {
        let parameters = [
            URLQueryItem(
                name: Parameter.before,
                value: DateFormatter.iso8601Format.string(from: date)
            ),
            URLQueryItem(
                name: Parameter.cryptoCurrency,
                value: cryptoCurrency.code
            ),
            URLQueryItem(
                name: Parameter.fiatCurrency,
                value: fiatCurrency
            ),
            URLQueryItem(
                name: Parameter.limit,
                value: "\(limit)"
            )
        ]
        let path = Path.activity
        let headers = [HttpHeaderField.authorization: token]
        let request = requestBuilder.get(
            path: path,
            parameters: parameters,
            headers: headers
        )!
        return communicator.perform(request: request)
    }
    
    public func fetchActivity(from date: Date, fiatCurrency: String, token: String) -> Single<[SwapActivityItemEvent]> {
        let parameters = [
            URLQueryItem(
                name: Parameter.before,
                value: DateFormatter.iso8601Format.string(from: date)
            ),
            URLQueryItem(
                name: Parameter.fiatCurrency,
                value: fiatCurrency
            )
        ]
        let path = Path.activity
        let headers = [HttpHeaderField.authorization: token]
        let request = requestBuilder.get(
            path: path,
            parameters: parameters,
            headers: headers
        )!
        return communicator.perform(request: request)
    }
    
}
