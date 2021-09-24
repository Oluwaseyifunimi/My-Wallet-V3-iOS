// Copyright © Blockchain Luxembourg S.A. All rights reserved.

import ComposableArchitecture
@testable import FeatureAccountPickerUI
@testable import PlatformKit
@testable import PlatformUIKit
import RxSwift
import SnapshotTesting
import SwiftUI
import XCTest

class AccountPickerRowViewTests: XCTestCase {

    var isShowingMultiBadge: Bool = false

    let environment = AccountPickerRowEnvironment(
        mainQueue: .main,
        updateSingleAccount: { _ in nil },
        updateAccountGroup: { _ in nil }
    )

    let accountGroup = AccountPickerRow.AccountGroup(
        id: UUID(),
        title: "All Wallets",
        description: "Total Balance",
        fiatBalance: "$2,302.39",
        currencyCode: "USD"
    )

    let singleAccount = AccountPickerRow.SingleAccount(
        id: UUID(),
        title: "BTC Trading Wallet",
        description: "Bitcoin",
        fiatBalance: "$2,302.39",
        cryptoBalance: "0.21204887 BTC"
    )

    lazy var linkedBankAccountModel = AccountPickerRow.LinkedBankAccount(
        id: self.linkedBankAccount.identifier,
        title: "Title",
        description: "Description"
    )

    let linkedBankAccount = LinkedBankAccount(
        label: "LinkedBankAccount",
        accountNumber: "0",
        accountId: "0",
        accountType: .checking,
        currency: .USD,
        paymentType: .bankAccount,
        supportsDeposit: true,
        withdrawServiceAPI: MockWithdrawalServiceAPI()
    )

    @ViewBuilder func view(row: AccountPickerRow) -> some View {
        AccountPickerRowView(
            store: Store(
                initialState: row,
                reducer: accountPickerRowReducer,
                environment: environment
            ),
            badgeView: { identifier in
                switch identifier {
                case self.singleAccount.id:
                    let model: BadgeImageViewModel = .default(
                        image: CryptoCurrency.coin(.bitcoin).logoResource,
                        cornerRadius: .round,
                        accessibilityIdSuffix: ""
                    )
                    model.marginOffsetRelay.accept(0)
                    let view = BadgeImageViewRepresentable(viewModel: model, size: 32)
                    return AnyView(view)
                case self.accountGroup.id:
                    let model: BadgeImageViewModel = .primary(
                        image: .local(name: "icon-card", bundle: .platformUIKit),
                        cornerRadius: .round,
                        accessibilityIdSuffix: "walletBalance"
                    )
                    model.marginOffsetRelay.accept(0)
                    let view = BadgeImageViewRepresentable(viewModel: model, size: 32)
                    return AnyView(view)
                case self.linkedBankAccountModel.id:
                    let model: BadgeImageViewModel = .default(
                        image: .local(name: "icon-bank", bundle: .platformUIKit),
                        cornerRadius: .round,
                        accessibilityIdSuffix: ""
                    )
                    let view = BadgeImageViewRepresentable(viewModel: model, size: 32)
                    return AnyView(view)
                default:
                    return AnyView(EmptyView())
                }
            },
            iconView: { _ in
                let model: BadgeImageViewModel = .template(
                    image: .local(name: "ic-private-account", bundle: .platformUIKit),
                    templateColor: CryptoCurrency.coin(.bitcoin).brandColor,
                    backgroundColor: .white,
                    cornerRadius: .round,
                    accessibilityIdSuffix: ""
                )
                model.marginOffsetRelay.accept(1)
                let view = BadgeImageViewRepresentable(viewModel: model, size: 16)
                return AnyView(view)
            },
            multiBadgeView: { identity in
                guard self.isShowingMultiBadge else { return AnyView(EmptyView()) }

                switch identity {
                case self.linkedBankAccount.identifier:
                    let badges = SingleAccountBadgeFactory()
                        .badge(account: self.linkedBankAccount, action: .withdraw)
                        .map {
                            MultiBadgeViewModel(
                                layoutMargins: LinkedBankAccountCellPresenter.multiBadgeInsets,
                                height: 24.0,
                                badges: $0
                            )
                        }
                        .asDriver(onErrorJustReturn: .init())
                    let view = MultiBadgeViewRepresentable(viewModel: badges)
                    return AnyView(view)
                case self.singleAccount.id:
                    let model = MultiBadgeViewModel(
                        layoutMargins: UIEdgeInsets(
                            top: 8,
                            left: 72,
                            bottom: 16,
                            right: 24
                        ),
                        height: 24,
                        badges: [
                            DefaultBadgeAssetPresenter.makeLowFeesBadge(),
                            DefaultBadgeAssetPresenter.makeFasterBadge()
                        ]
                    )
                    let view = MultiBadgeViewRepresentable(viewModel: .just(model))
                    return AnyView(view)
                default:
                    return AnyView(EmptyView())
                }
            }
        )
        .fixedSize()
    }

    func testAccountGroup() {
        let accountGroupRow = AccountPickerRow.accountGroup(
            accountGroup
        )

        assertSnapshot(matching: view(row: accountGroupRow), as: .image)
    }

    func testSingleAccount() {
        let singleAccountRow = AccountPickerRow.singleAccount(
            singleAccount
        )

        assertSnapshot(matching: view(row: singleAccountRow), as: .image)

        isShowingMultiBadge = true

        assertSnapshot(matching: view(row: singleAccountRow), as: .image)
    }

    func testButton() {
        let buttonRow = AccountPickerRow.button(
            .init(
                id: UUID(),
                text: "+ Add New"
            )
        )

        assertSnapshot(matching: view(row: buttonRow), as: .image)
    }

    func testLinkedAccount() {
        let linkedAccountRow = AccountPickerRow.linkedBankAccount(
            linkedBankAccountModel
        )

        assertSnapshot(matching: view(row: linkedAccountRow), as: .image)

        isShowingMultiBadge = true

        assertSnapshot(matching: view(row: linkedAccountRow), as: .image)
    }
}

struct MockWithdrawalServiceAPI: WithdrawalServiceAPI {
    func withdrawFeeAndLimit(
        for currency: FiatCurrency,
        paymentMethodType: PaymentMethodPayloadType
    ) -> Single<WithdrawalFeeAndLimit> {
        .just(.init(
            minLimit: FiatValue.zero(currency: currency),
            fee: FiatValue.zero(currency: currency)
        ))
    }

    func withdrawal(
        for checkout: WithdrawalCheckoutData
    ) -> Single<Result<FiatValue, Error>> {
        fatalError("Not implemented")
    }

    func withdrawalFee(
        for currency: FiatCurrency,
        paymentMethodType: PaymentMethodPayloadType
    ) -> Single<FiatValue> {
        fatalError("Not implemented")
    }

    func withdrawalMinAmount(
        for currency: FiatCurrency,
        paymentMethodType: PaymentMethodPayloadType
    ) -> Single<FiatValue> {
        fatalError("Not implemented")
    }
}