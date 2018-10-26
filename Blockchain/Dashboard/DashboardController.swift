//
//  DashboardController.swift
//  Blockchain
//
//  Created by Maurice A. on 9/13/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import UIKit
import Charts
import RxSwift

@objc
final class DashboardController: UIViewController {

    // MARK: - Properties

    // TICKET: IOS-1511 - Do not store assetType in DashboardController
    var assetType: LegacyAssetType? {
        didSet {
            reload()
        }
    }

    // MARK: - Private Properties

    private let horizontalPadding: CGFloat = 15
    private let priceChartPadding: CGFloat = 20
    private let pricePreviewViewSpacing: CGFloat = 16
    private let wallet: Wallet
    private let tabControllerManager: TabControllerManager
    private var lastEthExchangeRate: NSDecimalNumber = 0
    private var defaultContentHeight: CGFloat = 0
    private var disposable: Disposable?
    private var priceChartContainerView: UIView?
    private var bitcoinPricePreviewView,
                etherPricePreviewView,
                bitcoinCashPricePreviewView,
                stellarPricePreviewView: PricePreviewView?

    // TICKET: IOS-1512 - Move formatters to a global formatter pool

    private lazy var numberFormatter: NumberFormatter = {
        NumberFormatter()
    }()

    private lazy var dateFormatter: DateFormatter = {
        DateFormatter()
    }()

    private lazy var currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        if let latestMultiAddressResponse = WalletManager.shared.latestMultiAddressResponse,
            let symbol = latestMultiAddressResponse.symbol_local.symbol {
                formatter.currencySymbol = symbol
        }
        return formatter
    }()

    private lazy var chartContainerViewController: BCPriceChartContainerViewController = {
        let theViewController = BCPriceChartContainerViewController()
        theViewController.modalPresentationStyle = .overCurrentContext
        theViewController.delegate = self
        return theViewController
    }()

    // TICKET: IOS-1249 - Refactor CardsViewController

    private lazy var cardsViewController: CardsViewController = {
        let theViewController = CardsViewController()
        theViewController.dashboardContentView = self.contentView
        theViewController.dashboardScrollView = self.scrollView
        return theViewController
    }()

    private lazy var balancesChartView: BCBalancesChartView = {
        let balancesChartViewFrame = CGRect(
            x: horizontalPadding,
            y: 16,
            width: view.frame.size.width - (horizontalPadding * 2),
            height: 425
        )
        let balancesChartView = BCBalancesChartView(frame: balancesChartViewFrame)
        balancesChartView.delegate = self
        balancesChartView.layer.masksToBounds = false
        balancesChartView.layer.cornerRadius = 4
        balancesChartView.layer.shadowOffset = CGSize(width: 0, height: 2)
        balancesChartView.layer.shadowRadius = 4
        balancesChartView.layer.shadowOpacity = 0.1
        return balancesChartView
    }()

    private lazy var contentView: UIView = {
        let theView = UIView(frame: CGRect.zero)
        theView.backgroundColor = .clear
        theView.clipsToBounds = true
        return theView
    }()

    // MARK: - IBOutlets
    
    @IBOutlet private var scrollView: UIScrollView!

    // MARK: - Initialization

    required init?(coder aDecoder: NSCoder) {
        wallet = WalletManager.shared.wallet
        tabControllerManager = AppCoordinator.shared.tabControllerManager
        lastEthExchangeRate = NSDecimalNumber(value: 0)
        super.init(coder: aDecoder)
    }

    deinit {
        disposable?.dispose()
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(resetScrollView),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )

        view.backgroundColor = .lightGray

        contentView.addSubview(balancesChartView)

        setupPricePreviewViews()

        let balancesChartHeight = balancesChartView.frame.size.height
        let titleLabelHeight: CGFloat = 40 + 16
        let pricePreviewHeight: CGFloat = 4 * 150
        let pricePreviewSpacing: CGFloat = 4 * 16
        let bottomPadding: CGFloat = 16

        defaultContentHeight = balancesChartHeight + titleLabelHeight + pricePreviewHeight + pricePreviewSpacing + bottomPadding

        let contentViewFrame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: defaultContentHeight)
        contentView.frame = contentViewFrame

        scrollView.addSubview(contentView)
        scrollView.contentSize = CGSize(width: scrollView.frame.size.width, height: contentViewFrame.size.height)

        cardsViewController.reloadCards()
    }

    // TICKET: IOS-1507 - Refactor to use autolayout
    // TODO: use UIStackView
    // swiftlint:disable:next function_body_length
    private func setupPricePreviewViews() {
        let priceChartsLabelHeight: CGFloat = 40
        let pricePreviewViewHeight: CGFloat = 150

        let priceChartContainerViewFrame = CGRect(
            x: horizontalPadding,
            y: balancesChartView.frame.origin.y + balancesChartView.frame.size.height + pricePreviewViewSpacing,
            width: view.frame.size.width - (horizontalPadding * 2),
            height: priceChartsLabelHeight + (pricePreviewViewHeight * 4) + (pricePreviewViewSpacing * 3)
        )

        let priceChartsLabelFrame = CGRect(x: 8, y: 0, width: (view.frame.size.width / 2), height: priceChartsLabelHeight)

        let bitcoinPricePreviewViewFrame = CGRect(
            x: 0,
            y: priceChartsLabelFrame.origin.y + priceChartsLabelFrame.size.height,
            width: view.frame.size.width - (horizontalPadding * 2),
            height: pricePreviewViewHeight
        )

        let etherPricePreviewViewFrame = bitcoinPricePreviewViewFrame.offsetBy(
            dx: 0,
            dy: pricePreviewViewHeight + pricePreviewViewSpacing
        )

        let bitcoinCashPricePreviewViewFrame = etherPricePreviewViewFrame.offsetBy(
            dx: 0,
            dy: pricePreviewViewHeight + pricePreviewViewSpacing
        )

        let stellarPricePreviewViewFrame = bitcoinCashPricePreviewViewFrame.offsetBy(
            dx: 0,
            dy: pricePreviewViewHeight + pricePreviewViewSpacing
        )

        priceChartContainerView = UIView(frame: priceChartContainerViewFrame)

        let priceChartsLabel = UILabel(frame: priceChartsLabelFrame)
        priceChartsLabel.textColor = .brandPrimary
        priceChartsLabel.font = UIFont(name: Constants.FontNames.montserratRegular, size: Constants.FontSizes.Large)
        priceChartsLabel.text = LocalizationConstants.Dashboard.priceCharts

        bitcoinPricePreviewView = PricePreviewViewFactory.create(for: .bitcoin, buttonTapped: {
            self.showChartContainerViewController(for: .bitcoin)
        })

        etherPricePreviewView = PricePreviewViewFactory.create(for: .ethereum, buttonTapped: {
            self.showChartContainerViewController(for: .ethereum)
        })

        bitcoinCashPricePreviewView = PricePreviewViewFactory.create(for: .bitcoinCash, buttonTapped: {
            self.showChartContainerViewController(for: .bitcoinCash)
        })

        stellarPricePreviewView = PricePreviewViewFactory.create(for: .stellar, buttonTapped: {
            self.showChartContainerViewController(for: .stellar)
        })

        bitcoinPricePreviewView!.frame = bitcoinPricePreviewViewFrame
        etherPricePreviewView!.frame = etherPricePreviewViewFrame
        bitcoinCashPricePreviewView!.frame = bitcoinCashPricePreviewViewFrame
        stellarPricePreviewView!.frame = stellarPricePreviewViewFrame

        priceChartContainerView!.addSubview(priceChartsLabel)
        priceChartContainerView!.addSubview(bitcoinPricePreviewView!)
        priceChartContainerView!.addSubview(etherPricePreviewView!)
        priceChartContainerView!.addSubview(bitcoinCashPricePreviewView!)
        priceChartContainerView!.addSubview(stellarPricePreviewView!)
        contentView.addSubview(priceChartContainerView!)
    }

    private func showChartContainerViewController(for assetType: AssetType) {
        let pricePreviewChartPosition: Int
        let legacyAssetType: LegacyAssetType
        switch assetType {
        case .bitcoin:
            pricePreviewChartPosition = 0
            legacyAssetType = .bitcoin
        case .ethereum:
            pricePreviewChartPosition = 1
            legacyAssetType = .ether
        case .bitcoinCash:
            pricePreviewChartPosition = 2
            legacyAssetType = .bitcoinCash
        case .stellar:
            pricePreviewChartPosition = 3
            legacyAssetType = .stellar
        }

        let priceChartViewFrame = CGRect(
            x: priceChartPadding,
            y: priceChartPadding,
            width: self.view.frame.size.width - priceChartPadding,
            height: (self.view.frame.size.height * 0.75) - priceChartPadding
        )
        let priceChartView = BCPriceChartView(
            frame: priceChartViewFrame,
            assetType: legacyAssetType,
            dataPoints: nil,
            delegate: self
        )
        chartContainerViewController.add(priceChartView, at: pricePreviewChartPosition)
        // TICKET: IOS-1508 - Encapsulate getBtcPrice, getEthPrice and getBchPrice into separate component & decouple from DashboardController.
        fetchChartDataForAsset(type: assetType)

        if chartContainerViewController.presentingViewController == nil {
            tabControllerManager.present(chartContainerViewController, animated: true)
        }
    }

    // Objc backward compatible method to set asset type
    @objc func setAssetType(_ assetType: LegacyAssetType) {
        self.assetType = assetType
    }

    // Objc backward compatible method to set asset ethereum exchange rate
    @objc func updateEthExchangeRate(_ rate: NSDecimalNumber) {
        self.lastEthExchangeRate = rate
        reloadPricePreviews()
    }

    // TICKET: IOS-1506 - Encapsulate methods to get balances into separate component & decouple from DashboardController
    // swiftlint:disable:next function_body_length
    @objc func reload() {
        guard wallet.isInitialized() else {
            Logger.shared.warning("Returning nil because wallet was not initialized!")
            return
        }
        let btcFiatBalance = getBtcBalance()
        let ethFiatBalance = getEthBalance()
        let bchFiatBalance = getBchBalance()

        // TODO: display XLM balance...
        self.balancesChartView.updateStellarBalance("0")

        let watchOnlyFiatBalance = getBtcWatchOnlyBalance()
        guard let latestMultiAddressResponse = WalletManager.shared.latestMultiAddressResponse,
            let symbolLocal = latestMultiAddressResponse.symbol_local,
            let symbol = symbolLocal.symbol else {
                Logger.shared.warning("Failed to get symbol from latestMultiAddressResponse!")
                return
        }

        let truncatedEthBalance = wallet.getEthBalanceTruncated()

        let bchBalance = wallet.getBchBalance()

        let totalActiveBalance = wallet.getTotalActiveBalance()

        let totalFiatBalance = btcFiatBalance + ethFiatBalance + bchFiatBalance

        let walletIsInitialized = wallet.isInitialized()

        if walletIsInitialized {
            balancesChartView.updateFiatSymbol(symbol)
            // Fiat balances
            balancesChartView.updateBitcoinFiatBalance(btcFiatBalance)
            balancesChartView.updateEtherFiatBalance(ethFiatBalance)
            balancesChartView.updateBitcoinCashFiatBalance(bchFiatBalance)
            balancesChartView.updateTotalFiatBalance(
                NumberFormatter.appendString(toFiatSymbol: NumberFormatter.fiatString(from: totalFiatBalance))
            )
            // Balances
            balancesChartView.updateBitcoinBalance(NumberFormatter.formatAmount(totalActiveBalance, localCurrency: false))
            balancesChartView.updateEtherBalance(truncatedEthBalance)
            balancesChartView.updateBitcoinCashBalance(NumberFormatter.formatAmount(bchBalance, localCurrency: false))
            // Watch-only balances
            let watchOnlyBalance = wallet.getWatchOnlyBalance()
            if watchOnlyBalance > 0 {
                balancesChartView.updateBitcoinWatchOnlyFiatBalance(watchOnlyFiatBalance)
                balancesChartView.updateBitcoinWatchOnlyBalance(NumberFormatter.formatAmount(watchOnlyBalance, localCurrency: false))
                // Increase height and Y positions to show watch only view
                balancesChartView.showWatchOnlyView()
                let offset = balancesChartView.frame.origin.y + balancesChartView.frame.size.height + pricePreviewViewSpacing
                priceChartContainerView?.changeYPosition(offset)
                contentView.changeHeight(defaultContentHeight + balancesChartView.watchOnlyViewHeight())
            } else {
                // Show default heights and Y positions
                balancesChartView.hideWatchOnlyView()
                let offset = balancesChartView.frame.origin.y + balancesChartView.frame.size.height + pricePreviewViewSpacing
                priceChartContainerView?.changeYPosition(offset)
                contentView.changeHeight(defaultContentHeight)
            }
        }

        balancesChartView.updateChart()

        if !walletIsInitialized {
            balancesChartView.clearLegendKeyBalances()
        }

        reloadPricePreviews()

        cardsViewController.reloadCards()
    }

    @objc func reloadSymbols() {
        balancesChartView.updateWatchOnlyViewBalance()
    }

    // swiftlint:disable:next function_body_length
    private func fetchChartDataForAsset(type: AssetType) {
        let timeFrame: GraphTimeFrame
        let graphTimeFrameKey = UserDefaults.Keys.graphTimeFrameKey.rawValue
        if let data = UserDefaults.standard.object(forKey: graphTimeFrameKey) as? Data,
            let theUnarchiveObject = NSKeyedUnarchiver.unarchiveObject(with: data) as? GraphTimeFrame {
            timeFrame = theUnarchiveObject
        } else {
            timeFrame = GraphTimeFrame.timeFrameWeek()
        }

        let startDate, entryDate: Int
        let base: String

        switch type {
        case .bitcoin:
            base = AssetType.bitcoin.symbol.lowercased()
            entryDate = timeFrame.startDateBitcoin()
        case .bitcoinCash:
            base = AssetType.bitcoinCash.symbol.lowercased()
            entryDate = timeFrame.startDateBitcoinCash()
        case .ethereum:
            base = AssetType.ethereum.symbol.lowercased()
            entryDate = timeFrame.startDateEther()
        case .stellar:
            base = AssetType.stellar.symbol.lowercased()
            entryDate = timeFrame.startDateStellar()
        }

        startDate = timeFrame.timeFrame == TimeFrameAll || timeFrame.startDate < entryDate ? entryDate : timeFrame.startDate

        guard let quote = NumberFormatter.localCurrencyCode() else {
            showError(message: LocalizationConstants.Dashboard.chartsError)
            return
        }

        let url = URL(string: BlockchainAPI.shared.chartsURL(for: base, quote: quote, startDate: startDate, scale: timeFrame.scale))!
        let task = NetworkManager.shared.session.dataTask(with: url, completionHandler: { data, response, error in
            if let theError = error {
                self.showError(message: theError.localizedDescription)
                return
            }
            guard let httpResponse = response as? HTTPURLResponse,
                (200...299).contains(httpResponse.statusCode),
                let mimeType = httpResponse.mimeType,
                mimeType == HttpHeaderValue.json,
                let theData = data,
                let json = try? JSONSerialization.jsonObject(with: theData, options: .allowFragments),
                let values = json as? [Any] else {
                    self.showError(message: LocalizationConstants.Dashboard.chartsError)
                    return
            }
            DispatchQueue.main.async {
                if values.isEmpty {
                    self.chartContainerViewController.clearChart()
                    self.showError(message: LocalizationConstants.Dashboard.chartsError)
                } else {
                    self.chartContainerViewController.updateChart(withValues: values)
                }
            }
        })
        task.resume()
    }

    // MARK: - Charts

    @objc private func resetScrollView() {
        scrollView.setContentOffset(CGPoint.zero, animated: false)
    }

    // MARK: - View Helpers

    private func showError(message: String) {
        guard BlockchainSettings.App.shared.isPinSet,
            AuthenticationCoordinator.shared.pinEntryViewController == nil,
            wallet.isInitialized(),
            tabControllerManager.tabViewController.selectedIndex() == Int32(Constants.Navigation.tabDashboard),
            ModalPresenter.shared.modalView == nil else {
                return
        }
        // NOTE: May have to be presented in `self.view.window.rootViewController` instead of `self`
        AlertViewPresenter.shared.standardError(message: message, title: LocalizationConstants.Errors.error, in: self)
    }

    // MARK: - Text Helpers

    private func dateStringFromGraphValue(value: Double) -> String {
        let key = UserDefaults.Keys.graphTimeFrameKey.rawValue
        if let data = UserDefaults.standard.object(forKey: key) as? Data,
            let timeFrame = NSKeyedUnarchiver.unarchiveObject(with: data) as? GraphTimeFrame,
            let dateFormat = timeFrame.dateFormat {
            dateFormatter.dateFormat = dateFormat
        } else {
            dateFormatter.dateFormat = GraphTimeFrame.timeFrameDay().dateFormat
        }
        return dateFormatter.string(from: Date(timeIntervalSince1970: value))
    }

    private func getBtcBalance() -> Double {
        let balance = wallet.getTotalActiveBalance()
        let amount = NumberFormatter.formatAmount(balance, localCurrency: true) ?? "0"
        return numberFormatter.number(from: amount)?.doubleValue ?? 0
    }

    private func getEthBalance() -> Double {
        guard let balance = wallet.getEthBalance() else {
            Logger.shared.warning("Failed to get ETH balance!")
            return 0
        }
        let amount = NumberFormatter.formatEth(
            toFiat: balance,
            exchangeRate: wallet.latestEthExchangeRate,
            localCurrencyFormatter: NumberFormatter.localCurrencyFormatter
        ) ?? "0"
        return numberFormatter.number(from: amount)?.doubleValue ?? 0
    }

    private func getBchBalance() -> Double {
        let balance = wallet.getBchBalance()
        let amount = NumberFormatter.formatBch(balance, localCurrency: true) ?? "0"
        return numberFormatter.number(from: amount)?.doubleValue ?? 0
    }

    private func getBtcWatchOnlyBalance() -> Double {
        let balance = wallet.getWatchOnlyBalance()
        let amount = NumberFormatter.formatAmount(balance, localCurrency: true) ?? "0"
        return numberFormatter.number(from: amount)?.doubleValue ?? 0
    }

    private func reloadPricePreviews() {
        disposable = PriceServiceClient().allPrices(fiatSymbol: "USD")
            .subscribeOn(MainScheduler.asyncInstance)
            .observeOn(MainScheduler.instance)
            .subscribe(onSuccess: { priceMap in
                AssetType.all.forEach { type in
                    let price = priceMap[type]?.price ?? 0
                    let formattedPrice = self.currencyFormatter.string(for: NSDecimalNumber(decimal: price))!
                    switch type {
                    case .bitcoin:
                        self.bitcoinPricePreviewView?.price = formattedPrice
                    case .ethereum:
                        self.etherPricePreviewView?.price = formattedPrice
                    case .bitcoinCash:
                        self.bitcoinCashPricePreviewView?.price = formattedPrice
                    case .stellar:
                        self.stellarPricePreviewView?.price = formattedPrice
                    }
                }
            }, onError: { error in
                Logger.shared.error(error.localizedDescription)
            })
    }
}

// MARK: - BCBalancesChartView Delegate

// TICKET: IOS-1510 - Decouple showTransactions* methods from tabControllerManager
extension DashboardController: BCBalancesChartViewDelegate {
    func bitcoinLegendTapped() {
        tabControllerManager.showTransactionsBitcoin()
    }

    func etherLegendTapped() {
        tabControllerManager.showTransactionsEther()
    }

    func bitcoinCashLegendTapped() {
        tabControllerManager.showTransactionsBitcoinCash()
    }

    func stellarLegendTapped() {
        // tabControllerManager.showTransactionsStellar()
    }

    func watchOnlyViewTapped() {
        BlockchainSettings.sharedAppInstance().symbolLocal = !BlockchainSettings.sharedAppInstance().symbolLocal
    }
}

// MARK: - BCPriceChartView Delegate

extension DashboardController: BCPriceChartViewDelegate {
    func addPriceChartView(_ assetType: LegacyAssetType) {
        showChartContainerViewController(for: AssetType.from(legacyAssetType: assetType))
    }

    func reloadPriceChartView(_ assetType: LegacyAssetType) {
        fetchChartDataForAsset(type: AssetType.from(legacyAssetType: assetType))
    }
}

// MARK: - IAxisValueFormatter

extension DashboardController: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        switch axis {
        case chartContainerViewController.leftAxis():
            guard let latestMultiAddressResponse = WalletManager.shared.latestMultiAddressResponse,
                let symbolLocal = latestMultiAddressResponse.symbol_local,
                let symbol = symbolLocal.symbol else {
                    Logger.shared.warning("Failed to get symbol from latestMultiAddressResponse!")
                    return String()
            }
            return String(format: "%@%.f", symbol, value)
        case chartContainerViewController.xAxis():
            return dateStringFromGraphValue(value: value) ?? String()
        default:
            Logger.shared.warning("Warning: no axis found!")
            return String()
        }
    }
}
