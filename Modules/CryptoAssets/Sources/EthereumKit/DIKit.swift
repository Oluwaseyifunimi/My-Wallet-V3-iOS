// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import DIKit
import FeatureTransactionDomain
import PlatformKit
import ToolKit

extension DependencyContainer {

    // MARK: - EthereumKit Module

    public static var ethereumKit = module {

        factory { APIClient() as TransactionPushClientAPI }
        factory { APIClient() as TransactionClientAPI }
        factory { APIClient() as TransactionFeeClientAPI }
        factory { APIClient() as BalanceClientAPI }
        factory { APIClient() as EthereumAccountClientAPI }

        factory(tag: CoinAssetModel.ethereum.typeTag) {
            EthereumExternalAssetAddressFactory() as CryptoReceiveAddressFactory
        }

        factory(tag: CryptoCurrency.coin(.ethereum)) { EthereumAsset() as CryptoAsset }

        single { EthereumAccountDetailsService() as EthereumAccountDetailsServiceAPI }

        single { EthereumWalletAccountRepository() as EthereumWalletAccountRepositoryAPI }

        single { EthereumHistoricalTransactionService() as EthereumHistoricalTransactionServiceAPI }

        factory { () -> AnyActivityItemEventDetailsFetcher<EthereumActivityItemEventDetails> in
            AnyActivityItemEventDetailsFetcher(api: EthereumActivityItemEventDetailsFetcher())
        }

        factory { EthereumTransactionBuildingService() as EthereumTransactionBuildingServiceAPI }

        factory { EthereumTransactionSendingService() as EthereumTransactionSendingServiceAPI }

        factory { EthereumFeeService() as EthereumFeeServiceAPI }

        factory { EthereumAccountService() as EthereumAccountServiceAPI }

        factory { EthereumKeyPairProvider() }

        factory { AnyKeyPairProvider<EthereumKeyPair>.ethereum() }

        factory { EthereumTransactionBuilder() as EthereumTransactionBuilderAPI }

        factory { EthereumTransactionSigner() as EthereumTransactionSignerAPI }

        factory { EthereumTransactionEncoder() as EthereumTransactionEncoderAPI }

        factory { EthereumTransactionDispatcher() as EthereumTransactionDispatcherAPI }

        single(tag: Tags.EthereumAccountService.isContractAddressCache) {
            Atomic<[String: Bool]>([:])
        }
    }
}

extension DependencyContainer {
    enum Tags {
        enum EthereumAccountService {
            static let isContractAddressCache = String(describing: Self.self)
        }
    }
}

extension AnyKeyPairProvider where Pair == EthereumKeyPair {

    fileprivate static func ethereum(
        ethereumKeyPairProvider: EthereumKeyPairProvider = resolve()
    ) -> AnyKeyPairProvider<Pair> {
        AnyKeyPairProvider<Pair>(provider: ethereumKeyPairProvider)
    }
}