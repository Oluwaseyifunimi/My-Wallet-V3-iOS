// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainComponentLibrary
import BlockchainNamespace
import Combine
import ComposableArchitecture
import ComposableArchitectureExtensions
import FeatureCoinDomain
import Localization
import SwiftUI
import ToolKit

public let coinViewReducer = Reducer<
    CoinViewState,
    CoinViewAction,
    CoinViewEnvironment
>.combine(
    graphViewReducer
        .pullback(
            state: \.graph,
            action: /CoinViewAction.graph,
            environment: { $0 }
        ),
    .init { state, action, environment in
        switch action {

        case .onAppear:
            return .merge(
                Effect(value: .observation(.start)),
                environment.kycStatusProvider()
                    .setFailureType(to: Error.self)
                    .combineLatest(
                        environment.accountsProvider().flatMap(\.snapshot)
                    )
                    .receive(on: environment.mainQueue.animation(.spring()))
                    .catchToEffect()
                    .map(CoinViewAction.update),
                environment.interestRatesRepository
                    .fetchRate(code: state.asset.code)
                    .result()
                    .receive(on: environment.mainQueue)
                    .eraseToEffect()
                    .map(CoinViewAction.fetchedInterestRate),
                environment.app.publisher(
                    for: blockchain.ux.asset[state.asset.code].watchlist.is.on,
                    as: Bool.self
                )
                .compactMap(\.value)
                .receive(on: environment.mainQueue)
                .eraseToEffect()
                .map(CoinViewAction.isOnWatchlist),
                .fireAndForget { [state] in
                    environment.app.post(event: blockchain.ux.asset[state.asset.code])
                }
            )

        case .onDisappear:
            return Effect(value: .observation(.stop))

        case .fetchedInterestRate(let result):
            state.interestRate = try? result.get()
            return .none

        case .isOnWatchlist(let isFavorite):
            state.isFavorite = isFavorite
            return .none

        case .addToWatchlist:
            return .fireAndForget { [state] in
                environment.app.post(
                    event: blockchain.ux.asset[state.asset.code].watchlist.add
                )
            }

        case .removeFromWatchlist:
            return .fireAndForget { [state] in
                environment.app.post(
                    event: blockchain.ux.asset[state.asset.code].watchlist.remove
                )
            }

        case .update(let update):
            switch update {
            case .success(let value):
                state.kycStatus = value.0
                state.accounts = value.1
            case .failure:
                state.error = .failedToLoad
                return .none
            }
            return .none

        case .reset:
            return .fireAndForget {
                environment.explainerService.resetAll()
            }

        case .observation(.event(let ref, context: let cxt)):
            guard let account = cxt[blockchain.ux.asset.account] as? Account.Snapshot else {
                return .none
            }
            switch ref.tag {
            case blockchain.ux.asset.account.sheet:
                if environment.explainerService.isAccepted(account) {
                    state.account = account
                } else {
                    return .fireAndForget {
                        environment.app.post(
                            event: blockchain.ux.asset.account.explainer[].ref(to: ref.context),
                            context: cxt
                        )
                    }
                }
            case blockchain.ux.asset.account.explainer:
                state.explainer = account
                return .none
            case blockchain.ux.asset.account.explainer.accept:
                state.explainer = nil
                return .fireAndForget {
                    environment.explainerService.accept(account)
                    environment.app.post(
                        event: blockchain.ux.asset.account.sheet[].ref(to: ref.context),
                        context: cxt
                    )
                }
            default:
                break
            }
            return .none
        case .dismiss:
            return .fireAndForget(environment.dismiss)
        case .graph, .binding, .observation:
            return .none
        }
    }
)
.on(blockchain.ux.asset.account.sheet)
.on(blockchain.ux.asset.account.explainer, blockchain.ux.asset.account.explainer.accept)
.binding()
