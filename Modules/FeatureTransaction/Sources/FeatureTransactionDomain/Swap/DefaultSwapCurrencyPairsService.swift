// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import BlockchainNamespace
import Foundation
import MoneyKit
import PlatformKit

public struct SelectionInformation: Equatable {
    public init(accountId: String, currency: CryptoCurrency) {
        self.accountId = accountId
        self.currency = currency
    }

    public var accountId: String
    public var currency: CryptoCurrency
}

public protocol DefaultSwapCurrencyPairsServiceAPI {
    func getDefaultPairs() async -> (source: SelectionInformation, target: SelectionInformation)?
}

public class DefaultSwapCurrencyPairsService: DefaultSwapCurrencyPairsServiceAPI {
    private let app: AppProtocol

    public init(
        app: AppProtocol
    ) {
        self.app = app
    }

    public func getDefaultPairs() async -> (source: SelectionInformation, target: SelectionInformation)? {
        let appMode = await app.mode()

        switch appMode {
        case .trading, .universal:
            return await getDefaultTradingPairs()
        case .pkw:
            return await getDefaultNonCustodialPairs()
        }
    }

    private func getDefaultTradingPairs() async -> (source: SelectionInformation, target: SelectionInformation)? {
        do {
            let custodialCurrencies = try await app.get(blockchain.user.trading.currencies, as: [String].self)
            let balance = try await custodialCurrencies
                .async
                .map { currency -> MoneyValuePair in
                    try await MoneyValuePair(
                        base: self.app.get(blockchain.user.trading.account[currency].balance.available),
                        exchangeRate: self.app.get(blockchain.api.nabu.gateway.price.at.time[PriceTime.now.id].crypto[currency].fiat.quote.value)
                    )
                }
                .reduce(into: []) { balances, moneyValuePair in
                    balances.append(moneyValuePair)
                }
                .sorted(by: { try $0.quote > $1.quote })
                .first.or(throw: "No matching pairs")

            let accountId = try? await app
                .get(blockchain.coin.core.accounts.custodial.asset[balance.base.currency.code], as: String.self)
            let bitcoinAccountId = try? await app
                .get(blockchain.coin.core.accounts.custodial.asset[CryptoCurrency.bitcoin.code], as: String.self)
            let usdtAccountId = try? await app
                .get(blockchain.coin.core.accounts.custodial.asset["USDT"], as: String.self)

            return try pair(
                with: balance.base.currency,
                accountId: accountId,
                usdtAccountId: usdtAccountId,
                bitcoinAccountId: bitcoinAccountId
            )
        } catch {
            return nil
        }
    }

    private func getDefaultNonCustodialPairs() async -> (source: SelectionInformation, target: SelectionInformation)? {
        do {
            let nonCustodialCurrencies = try await app.get(blockchain.user.pkw.currencies, as: [String].self)
            let balance = try await nonCustodialCurrencies
                .async
                .map { currency -> MoneyValuePair in
                    try await MoneyValuePair(
                        base: self.app.get(blockchain.user.pkw.asset[currency].balance),
                        exchangeRate: self.app.get(blockchain.api.nabu.gateway.price.at.time[PriceTime.now.id].crypto[currency].fiat.quote.value)
                    )
                }
                .reduce(into: []) { balances, moneyValuePair in
                    balances.append(moneyValuePair)
                }
                .sorted(by: { try $0.quote > $1.quote })
                .first.or(throw: "No matching pairs")

            let accountId: String? = try? await app
                .get(blockchain.coin.core.accounts.DeFi.asset[balance.base.currency.code], as: [String].self)
                .first
            let bitcoinAccountId: String? = try? await app
                .get(blockchain.coin.core.accounts.DeFi.asset[CryptoCurrency.bitcoin.code], as: [String].self)
                .first
            let usdtAccountId: String? = try? await app
                .get(blockchain.coin.core.accounts.DeFi.asset["USDT"], as: [String].self)
                .first

            return try pair(
                with: balance.base.currency,
                accountId: accountId,
                usdtAccountId: usdtAccountId,
                bitcoinAccountId: bitcoinAccountId
            )
        } catch {
            return nil
        }
    }

    private func pair(
        with currency: CurrencyType,
        accountId: String?,
        usdtAccountId: String?,
        bitcoinAccountId: String?,
        currenciesService: EnabledCurrenciesServiceAPI = EnabledCurrenciesService.default
    ) throws -> (source: SelectionInformation, target: SelectionInformation) {
        guard let cryptoCurrency = currency.cryptoCurrency else {
            throw "Not a cryptocurrency"
        }
        guard let accountId else {
            throw "No account id found"
        }
        let bitcoin = CryptoCurrency.bitcoin
        let source = SelectionInformation(accountId: accountId, currency: cryptoCurrency)
        let destination: SelectionInformation

        // If source is Bitcoin
        if cryptoCurrency == bitcoin {
            // Then target will be USDT
            let usdtAccountId = try usdtAccountId.or(throw: "No USDT account id found")
            let usdt = try currenciesService
                .allEnabledCryptoCurrencies
                .first(where: { $0.code == "USDT" })
                .or(throw: "No USDT found")
            destination = SelectionInformation(accountId: usdtAccountId, currency: usdt)
        } else {
            // Else target will be Bitcoin
            let bitcoinAccountId = try bitcoinAccountId.or(throw: "No BTC account id found")
            destination = SelectionInformation(accountId: bitcoinAccountId, currency: bitcoin)
        }
        return (source: source, target: destination)
    }
}