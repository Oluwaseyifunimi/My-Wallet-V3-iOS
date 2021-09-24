// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import Foundation
import NetworkError
import PlatformKit
import ToolKit

final class PriceRepository: PriceRepositoryAPI {

    // MARK: - Setup

    private let client: PriceClientAPI
    private let indexMultiCachedValue: CachedValueNew<
        PriceRequest.IndexMulti.Key,
        [String: PriceQuoteAtTime],
        NetworkError
    >
    private let symbolsCachedValue: CachedValueNew<
        PriceRequest.Symbols.Key,
        Set<String>,
        NetworkError
    >

    // MARK: - Setup

    init(client: PriceClientAPI = resolve()) {
        self.client = client
        let inMemoryCache = InMemoryCache<PriceRequest.IndexMulti.Key, [String: PriceQuoteAtTime]>(
            refreshControl: PeriodicCacheRefreshControl(refreshInterval: 60)
        )
        .eraseToAnyCache()
        indexMultiCachedValue = CachedValueNew(
            cache: inMemoryCache,
            fetch: { key in
                client
                    .price(of: key.base, in: key.quote.code, time: key.time.timestamp)
                    .map(\.entries)
                    .map { entries in
                        entries.mapValues { item in
                            PriceQuoteAtTime(
                                timestamp: item.timestamp,
                                moneyValue: .create(major: item.price, currency: key.quote.currencyType)
                            )
                        }
                    }
                    .eraseToAnyPublisher()
            }
        )
        symbolsCachedValue = CachedValueNew(
            cache: InMemoryCache<PriceRequest.Symbols.Key, Set<String>>(
                refreshControl: PerpetualCacheRefreshControl()
            )
            .eraseToAnyCache(),
            fetch: { _ in
                client.symbols()
                    .map(\.base.keys)
                    .map(Set.init)
                    .eraseToAnyPublisher()
            }
        )
    }

    func prices(
        of bases: [Currency],
        in quote: Currency,
        at time: PriceTime
    ) -> AnyPublisher<[String: PriceQuoteAtTime], NetworkError> {
        symbolsCachedValue
            .get(key: PriceRequest.Symbols.Key())
            .flatMap { [indexMultiCachedValue] supportedBases
                -> AnyPublisher<[String: PriceQuoteAtTime], NetworkError> in
                indexMultiCachedValue
                    .get(
                        key: PriceRequest.IndexMulti.Key(
                            base: Set(bases.map(\.code)).intersection(supportedBases),
                            quote: quote.currencyType,
                            time: time
                        )
                    )
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    func priceSeries(
        of base: CryptoCurrency,
        in quote: FiatCurrency,
        within window: PriceWindow
    ) -> AnyPublisher<HistoricalPriceSeries, NetworkError> {
        let start: TimeInterval = window.timeIntervalSince1970(
            calendar: .current,
            date: Date()
        )
        return client
            .priceSeries(
                of: base.code,
                in: quote.code,
                start: start.string(with: 0),
                scale: String(window.scale)
            )
            .map { response in
                HistoricalPriceSeries(baseCurrency: base, quoteCurrency: quote, prices: response)
            }
            .eraseToAnyPublisher()
    }
}

extension HistoricalPriceSeries {

    init(baseCurrency: CryptoCurrency, quoteCurrency: Currency, prices: [PriceResponse.Item]) {
        self.init(
            currency: baseCurrency,
            prices: prices.map { item in
                PriceQuoteAtTime(response: item, currency: quoteCurrency)
            }
        )
    }
}

extension PriceQuoteAtTime {

    init(response: PriceResponse.Item, currency: Currency) {
        self.init(
            timestamp: response.timestamp,
            moneyValue: .create(major: response.price, currency: currency.currencyType)
        )
    }
}