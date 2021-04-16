//
//  TradingToOnChainTransactionEngine.swift
//  TransactionKit
//
//  Created by Alex McGregor on 2/2/21.
//  Copyright © 2021 Blockchain Luxembourg S.A. All rights reserved.
//

import DIKit
import PlatformKit
import RxSwift
import ToolKit

final class TradingToOnChainTransactionEngine: TransactionEngine {
    
    /// This might need to be `1:1` as there isn't a transaction pair.
    var transactionExchangeRatePair: Observable<MoneyValuePair> {
        .empty()
    }
    
    var fiatExchangeRatePairs: Observable<TransactionMoneyValuePairs> {
        sourceExchangeRatePair
            .map { pair -> TransactionMoneyValuePairs in
                TransactionMoneyValuePairs(
                    source: pair,
                    destination: pair
                )
            }
            .asObservable()
    }
    
    let fiatCurrencyService: FiatCurrencyServiceAPI
    let priceService: PriceServiceAPI
    let requireSecondPassword: Bool = false
    let isNoteSupported: Bool
    var askForRefreshConfirmation: ((Bool) -> Completable)!
    var sourceAccount: CryptoAccount!
    var transactionTarget: TransactionTarget!

    var sourceTradingAccount: CryptoTradingAccount! {
        sourceAccount as? CryptoTradingAccount
    }
    
    var target: CryptoAccount { transactionTarget as! CryptoAccount }
    var targetAsset: CryptoCurrency { target.asset }
    var sourceAsset: CryptoCurrency { sourceAccount.asset }
    
    // MARK: - Private Properties
    
    private let transferService: InternalTransferServiceAPI
    
    // MARK: - Init

    init(isNoteSupported: Bool = false,
         fiatCurrencyService: FiatCurrencyServiceAPI = resolve(),
         priceService: PriceServiceAPI = resolve(),
         transferService: InternalTransferServiceAPI = resolve()) {
        self.fiatCurrencyService = fiatCurrencyService
        self.priceService = priceService
        self.isNoteSupported = isNoteSupported
        self.transferService = transferService
    }
    
    func assertInputsValid() {
        precondition(target is CryptoNonCustodialAccount)
        precondition(sourceAccount is CryptoTradingAccount)
        precondition((target as! CryptoNonCustodialAccount).asset == sourceAccount.asset)
    }

    func initializeTransaction() -> Single<PendingTransaction> {
        fiatCurrencyService
            .fiatCurrency
            .flatMap(weak: self) { (self, fiatCurrency) -> Single<PendingTransaction> in
                .just(
                    .init(
                        amount: .zero(currency: self.sourceAsset),
                        available: .zero(currency: self.sourceAsset),
                        feeAmount: .zero(currency: self.sourceAsset),
                        feeForFullAvailable: .zero(currency: self.sourceAsset),
                        feeSelection: .empty(asset: self.sourceAsset),
                        selectedFiatCurrency: fiatCurrency,
                        minimumLimit: .zero(currency: self.sourceAsset)
                    )
                )
            }
    }
    
    func update(amount: MoneyValue, pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        guard sourceTradingAccount != nil else {
            return .just(pendingTransaction)
        }
        return sourceTradingAccount
            .withdrawableBalance
            .map { actionableBalance -> PendingTransaction in
                pendingTransaction.update(amount: amount, available: actionableBalance)
            }
    }
    
    func doBuildConfirmations(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        fiatAmountAndFees(from: pendingTransaction)
            .map(\.amount)
            .map(weak: self) { (self, amount) -> [TransactionConfirmation] in
                var confirmations: [TransactionConfirmation] = [
                    .source(.init(value: self.sourceAccount.label)),
                    .destination(.init(value: self.target.label)),
                    .total(.init(total: amount.moneyValue))
                ]
                if self.isNoteSupported {
                    confirmations.append(.destination(.init(value: "")))
                }
                return confirmations
            }
            .map { confirmations -> PendingTransaction in
                pendingTransaction.update(confirmations: confirmations)
            }
    }
    
    func validateAmount(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        validateAmounts(pendingTransaction: pendingTransaction)
            .updateTxValidityCompletable(pendingTransaction: pendingTransaction)
    }
    
    func doValidateAll(pendingTransaction: PendingTransaction) -> Single<PendingTransaction> {
        validateAmounts(pendingTransaction: pendingTransaction)
            .updateTxValidityCompletable(pendingTransaction: pendingTransaction)
    }

    func execute(pendingTransaction: PendingTransaction, secondPassword: String) -> Single<TransactionResult> {
        target
            .receiveAddress
            .map(\.address)
            .flatMap(weak: self) { (self, destination) -> Single<TransactionResult> in
                self.transferService
                    .transfer(
                        moneyValue: pendingTransaction.amount,
                        destination: destination
                    )
                    .map(\.identifier)
                    .map { (identifier) -> TransactionResult in
                        TransactionResult.hashed(txHash: identifier, amount: pendingTransaction.amount)
                    }
            }
    }
    
    func doPostExecute(transactionResult: TransactionResult) -> Completable {
        target.onTxCompleted(transactionResult)
    }
    
    func doUpdateFeeLevel(pendingTransaction: PendingTransaction,
                          level: FeeLevel,
                          customFeeAmount: MoneyValue) -> Single<PendingTransaction> {
        precondition(pendingTransaction.availableFeeLevels.contains(level))
        /// `TradingToOnChainTransactionEngine` only supports a
        /// `FeeLevel` of `.none`
        return .just(pendingTransaction)
    }
    
    // MARK: - Private Functions
    
    private func validateAmounts(pendingTransaction: PendingTransaction) -> Completable {
        sourceTradingAccount
            .withdrawableBalance
            .flatMapCompletable(weak: self) { (self, balance) -> Completable in
                guard try pendingTransaction.amount > .zero(currency: self.sourceAsset) else {
                    throw TransactionValidationFailure(state: .invalidAmount)
                }
                guard try balance >= pendingTransaction.amount else {
                    throw TransactionValidationFailure(state: .insufficientFunds)
                }
                return .just(event: .completed)
            }
    }

    private func fiatAmountAndFees(from pendingTransaction: PendingTransaction) -> Single<(amount: FiatValue, fees: FiatValue)> {
        Single.zip(
            sourceExchangeRatePair,
            .just(pendingTransaction.amount.cryptoValue ?? .zero(currency: sourceAsset)),
            .just(pendingTransaction.feeAmount.cryptoValue ?? .zero(currency: sourceAsset))
        )
        .map({ (quote: ($0.0.quote.fiatValue ?? .zero(currency: .USD)), amount: $0.1, fees: $0.2) })
        .map { (quote: (FiatValue), amount: CryptoValue, fees: CryptoValue) -> (FiatValue, FiatValue) in
            let fiatAmount = amount.convertToFiatValue(exchangeRate: quote)
            let fiatFees = fees.convertToFiatValue(exchangeRate: quote)
            return (fiatAmount, fiatFees)
        }
        .map { (amount: $0.0, fees: $0.1) }
    }
    
    private var sourceExchangeRatePair: Single<MoneyValuePair> {
        fiatCurrencyService
            .fiatCurrency
            .flatMap(weak: self) { (self, fiatCurrency) -> Single<MoneyValuePair> in
                self.priceService
                    .price(for: self.sourceAccount.currencyType, in: fiatCurrency)
                    .map(\.moneyValue)
                    .map { MoneyValuePair(base: .one(currency: self.sourceAccount.currencyType), quote: $0) }
            }
    }
}