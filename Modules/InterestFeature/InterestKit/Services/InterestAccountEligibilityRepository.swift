// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import DIKit
import PlatformKit

public enum InterestAccountEligibilityError: Error {
    case networkError(Error)
}

public protocol InterestAccountEligibilityRepositoryAPI {
    func fetchInterestAccountEligibilityForCurrencyCode(
        _ code: String
    ) -> AnyPublisher<InterestAccountEligibility, InterestAccountEligibilityError>
}

final class InterestAccountEligibilityRepository: InterestAccountEligibilityRepositoryAPI {

    private let enabledCurrenciesService: EnabledCurrenciesServiceAPI
    private let client: InterestAccountEligibilityClientAPI

    init(
        client: InterestAccountEligibilityClientAPI = resolve(),
        enabledCurrenciesService: EnabledCurrenciesServiceAPI = resolve()
    ) {
        self.enabledCurrenciesService = enabledCurrenciesService
        self.client = client
    }

    func fetchInterestAccountEligibilityForCurrencyCode(
        _ code: String
    ) -> AnyPublisher<InterestAccountEligibility, InterestAccountEligibilityError> {
        fetchInterestAccountEligibilities()
            .map { $0.filter { $0.currencyType.code == code } }
            .compactMap(\.first)
            .eraseToAnyPublisher()
    }

    private func fetchInterestAccountEligibilities()
        -> AnyPublisher<[InterestAccountEligibility], InterestAccountEligibilityError>
    {
        client
            .fetchInterestAccountEligibilityResponse()
            .mapError(InterestAccountEligibilityError.networkError)
            .map { [enabledCurrenciesService] response -> [InterestAccountEligibility] in
                enabledCurrenciesService
                    .allEnabledCurrencies
                    .map { asset -> InterestAccountEligibility in
                        guard let eligibility = response[asset] else {
                            return InterestAccountEligibility.notEligible(currencyType: asset)
                        }
                        return InterestAccountEligibility(currencyType: asset, interestEligibility: eligibility)
                    }
            }
            .eraseToAnyPublisher()
    }
}