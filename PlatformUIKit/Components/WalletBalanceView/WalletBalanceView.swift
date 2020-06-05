//
//  WalletBalanceView.swift
//  PlatformUIKit
//
//  Created by Alex McGregor on 5/14/20.
//  Copyright © 2020 Blockchain Luxembourg S.A. All rights reserved.
//

import RxCocoa
import RxSwift

public final class WalletBalanceView: UIView {
    
    // MARK: - Injected
    
    public var presenter: WalletBalanceViewPresenter! {
        willSet {
            disposeBag = DisposeBag()
        }
        didSet {
            guard let presenter = presenter else {
                return
            }
            
            accessibility = presenter.accessibility
            
            presenter.alignment
                .drive(stackView.rx.alignment)
                .disposed(by: disposeBag)
            
            presenter.state
                .compactMap { $0.value }
                .bind(to: rx.values)
                .disposed(by: disposeBag)
            
            presenter.state
                .map { $0.isLoading }
                .mapToVoid()
                .bind { [weak self] in
                    self?.startShimmering()
                }
                .disposed(by: disposeBag)
                
            presenter.state
                .filter { $0.isLoading == false }
                .mapToVoid()
                .bind { [weak self] in
                    self?.stopShimmering()
                }
                .disposed(by: disposeBag)
        }
    }
    
    // MARK: - Private IBOutlets
    
    @IBOutlet private var stackView: UIStackView!
    @IBOutlet fileprivate var fiatBalanceLabel: UILabel!
    @IBOutlet fileprivate var currencyCodeLabel: UILabel!
    
    fileprivate var fiatLabelShimmeringView: ShimmeringView!
    fileprivate var currencyCodeLabelShimmeringView: ShimmeringView!
    
    private var disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    /// Should be called once when the parent view loads
    public func shimmer(estimatedFiatLabelSize: CGSize, estimatedCryptoLabelSize: CGSize) {
        fiatLabelShimmeringView = ShimmeringView(
            in: self,
            anchorView: fiatBalanceLabel,
            size: estimatedFiatLabelSize
        )
        currencyCodeLabelShimmeringView = ShimmeringView(
            in: self,
            anchorView: currencyCodeLabel,
            size: estimatedCryptoLabelSize
        )
    }
    
    private func setup() {
        fromNib()
    }
    
    private func stopShimmering() {
        guard fiatLabelShimmeringView != nil else { return }
        guard currencyCodeLabelShimmeringView != nil else { return }
        guard fiatLabelShimmeringView.isShimmering &&
            currencyCodeLabelShimmeringView.isShimmering else { return }
        
        fiatBalanceLabel.alpha = 0
        currencyCodeLabel.alpha = 0
        
        let animation = {
            self.fiatBalanceLabel.alpha = 1
            self.currencyCodeLabel.alpha = 1
            self.fiatLabelShimmeringView.stop()
            self.currencyCodeLabelShimmeringView.stop()
        }
        
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: [.curveEaseInOut, .transitionCrossDissolve],
            animations: animation
        )
    }
    
    private func startShimmering() {
        guard fiatBalanceLabel.content.isEmpty else { return }
        guard currencyCodeLabel.content.isEmpty else { return }
        fiatLabelShimmeringView.start()
        currencyCodeLabelShimmeringView.start()
    }
}

// MARK: - Rx

extension Reactive where Base: WalletBalanceView {
    var values: Binder<WalletBalanceViewPresenter.WalletBalance> {
        Binder(base) { view, values in
            view.fiatBalanceLabel.content = values.fiatBalance
            view.currencyCodeLabel.content = values.currencyCode
        }
    }
}
