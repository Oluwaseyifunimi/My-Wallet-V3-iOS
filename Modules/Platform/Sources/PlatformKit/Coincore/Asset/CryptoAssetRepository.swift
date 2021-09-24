// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import Combine
import Localization
import RxSwift
import ToolKit

public protocol CryptoAssetRepositoryAPI {

    var allAccountsGroup: AnyPublisher<AccountGroup, Never> { get }

    var custodialGroup: AnyPublisher<AccountGroup, Never> { get }

    var nonCustodialGroup: AnyPublisher<AccountGroup, Never> { get }

    var exchangeGroup: AnyPublisher<AccountGroup, Never> { get }

    var interestGroup: AnyPublisher<AccountGroup, Never> { get }

    var canTransactToCustodial: AnyPublisher<Bool, Never> { get }

    func accountGroup(
        filter: AssetFilter
    ) -> AnyPublisher<AccountGroup, Never>

    func parse(address: String) -> AnyPublisher<ReceiveAddress?, Never>
}

public final class CryptoAssetRepository: CryptoAssetRepositoryAPI {

    // MARK: - Types

    public typealias DefaultAccountProvider =
        () -> AnyPublisher<SingleAccount, CryptoAssetError>

    public typealias ExchangeAccountProvider =
        () -> AnyPublisher<CryptoExchangeAccount?, Never>

    // MARK: - Properties

    public var nonCustodialGroup: AnyPublisher<AccountGroup, Never> {
        defaultAccountProvider()
            .map { [asset] account -> AccountGroup in
                CryptoAccountNonCustodialGroup(asset: asset, accounts: [account])
            }
            .recordErrors(on: errorRecorder)
            .replaceError(with: CryptoAccountNonCustodialGroup(asset: asset, accounts: []))
            .eraseToAnyPublisher()
    }

    public var canTransactToCustodial: AnyPublisher<Bool, Never> {
        kycTiersService.tiers
            .asObservable()
            .asPublisher()
            .map { tiers in
                tiers.isTier1Approved || tiers.isTier2Approved
            }
            .replaceError(with: false)
            .eraseToAnyPublisher()
    }

    public var allAccountsGroup: AnyPublisher<AccountGroup, Never> {
        [
            nonCustodialGroup,
            custodialGroup,
            interestGroup,
            exchangeGroup
        ]
        .zip()
        .eraseToAnyPublisher()
        .flatMapAllAccountGroup()
    }

    public var exchangeGroup: AnyPublisher<AccountGroup, Never> {
        guard asset.supports(product: .mercuryDeposits) else {
            return .just(CryptoAccountCustodialGroup(asset: asset))
        }
        return exchangeAccountsProvider.account(for: asset)
            .optional()
            .replaceError(with: nil)
            .eraseToAnyPublisher()
            .map { [asset] account -> CryptoAccountCustodialGroup in
                guard let account = account else {
                    return CryptoAccountCustodialGroup(asset: asset)
                }
                return CryptoAccountCustodialGroup(asset: asset, account: account)
            }
            .eraseToAnyPublisher()
    }

    public var interestGroup: AnyPublisher<AccountGroup, Never> {
        guard asset.supports(product: .interestBalance) else {
            return .just(CryptoAccountCustodialGroup(asset: asset))
        }
        return .just(
            CryptoAccountCustodialGroup(
                asset: asset,
                account: CryptoInterestAccount(asset: asset)
            )
        )
    }

    public var custodialGroup: AnyPublisher<AccountGroup, Never> {
        guard asset.supports(product: .custodialWalletBalance) else {
            return .just(CryptoAccountCustodialGroup(asset: asset))
        }
        return .just(
            CryptoAccountCustodialGroup(
                asset: asset,
                account: CryptoTradingAccount(asset: asset)
            )
        )
    }

    // MARK: - Private properties

    private let asset: CryptoCurrency
    private let errorRecorder: ErrorRecording
    private let kycTiersService: KYCTiersServiceAPI
    private let defaultAccountProvider: DefaultAccountProvider
    private let exchangeAccountsProvider: ExchangeAccountsProviderAPI
    private let addressFactory: CryptoReceiveAddressFactory

    // MARK: - Setup

    public init(
        asset: CryptoCurrency,
        errorRecorder: ErrorRecording,
        kycTiersService: KYCTiersServiceAPI,
        defaultAccountProvider: @escaping DefaultAccountProvider,
        exchangeAccountsProvider: ExchangeAccountsProviderAPI,
        addressFactory: CryptoReceiveAddressFactory
    ) {
        self.asset = asset
        self.errorRecorder = errorRecorder
        self.kycTiersService = kycTiersService
        self.defaultAccountProvider = defaultAccountProvider
        self.exchangeAccountsProvider = exchangeAccountsProvider
        self.addressFactory = addressFactory
    }

    // MARK: - Public methods

    public func accountGroup(filter: AssetFilter) -> AnyPublisher<AccountGroup, Never> {
        switch filter {
        case .all:
            return allAccountsGroup
        case .custodial:
            return custodialGroup
        case .interest:
            return interestGroup
        case .nonCustodial:
            return nonCustodialGroup
        case .exchange:
            return exchangeGroup
        }
    }

    public func parse(address: String) -> AnyPublisher<ReceiveAddress?, Never> {
        let receiveAddress = try? addressFactory
            .makeExternalAssetAddress(
                asset: asset,
                address: address,
                label: address,
                onTxCompleted: { _ in .empty() }
            )
            .get()
        return .just(receiveAddress)
    }
}