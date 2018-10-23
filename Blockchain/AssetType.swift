//
//  AssetType.swift
//  Blockchain
//
//  Created by Maurice A. on 4/13/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation

/// The asset type is used to distinguish between different types of digital assets.
@objc public enum AssetType: Int {
    case bitcoin, bitcoinCash, ethereum, stellar
}

extension AssetType {
    
    private static let assetTypeToSymbolMap: [String: AssetType] = [
        "btc": .bitcoin,
        "eth": .ethereum,
        "bch": .bitcoinCash,
        "xlm": .stellar
    ]

    static let all: [AssetType] = {
        var allAssets: [AssetType] = [.bitcoin, .ethereum, .bitcoinCash]
        if AppFeatureConfigurator.shared.configuration(for: .stellar).isEnabled {
            allAssets.append(.stellar)
        }
        return allAssets
    }()
    
    static func from(legacyAssetType: LegacyAssetType) -> AssetType {
        switch legacyAssetType {
        case .bitcoin:
            return AssetType.bitcoin
        case .bitcoinCash:
            return AssetType.bitcoinCash
        case .ether:
            return AssetType.ethereum
        case .stellar:
            return AssetType.stellar
        }
    }

    init?(stringValue: String) {
        let input = stringValue.lowercased()
        let map = AssetType.assetTypeToSymbolMap
        if let value = map[input] {
            self = value
        } else {
            return nil
        }
    }

    var legacy: LegacyAssetType {
        switch self {
        case .bitcoin:
            return LegacyAssetType.bitcoin
        case .bitcoinCash:
            return LegacyAssetType.bitcoinCash
        case .ethereum:
            return LegacyAssetType.ether
        case .stellar:
            return LegacyAssetType.stellar
        }
    }
}

extension AssetType {
    var description: String {
        switch self {
        case .bitcoin:
            return "Bitcoin"
        case .bitcoinCash:
            return "Bitcoin Cash"
        case .ethereum:
            return "Ether"
        case .stellar:
            return "Stellar"
        }
    }

    var symbol: String {
        switch self {
        case .bitcoin:
            return "BTC"
        case .bitcoinCash:
            return "BCH"
        case .ethereum:
            return "ETH"
        case .stellar:
            return "XLM"
        }
    }
    
    var brandImage: UIImage {
        switch self {
        case .bitcoin:
            return #imageLiteral(resourceName: "Icon-BTC")
        case .bitcoinCash:
            return #imageLiteral(resourceName: "Icon-BCH")
        case .ethereum:
            return #imageLiteral(resourceName: "Icon-ETH")
        case .stellar:
            // TODO: use image assets
            return #imageLiteral(resourceName: "Icon-ETH")
        }
    }
    
    var brandColor: UIColor {
        switch self {
        case .bitcoin:
            return UIColor(red: 1, green: 0.61, blue: 0.13, alpha: 1)
        case .ethereum:
            return UIColor(red: 0.28, green: 0.23, blue: 0.8, alpha: 1)
        case .bitcoinCash:
            return UIColor(red: 0.24, green: 0.86, blue: 0.54, alpha: 1)
        case .stellar:
            return UIColor(red: 0.02, green: 0.71, blue: 0.90, alpha: 1)
        }
    }
    
    func toFiat(
        amount: Decimal,
        from wallet: Wallet = WalletManager.shared.wallet
    ) -> String? {
        let input = amount as NSDecimalNumber
        
        switch self {
        case .bitcoin:
            let value = NumberFormatter.parseBtcValue(from: input.stringValue)
            return NumberFormatter.formatMoney(
                value.magnitude,
                localCurrency: true
            )
        case .ethereum:
            let value = NumberFormatter.formatEthToFiat(
                withSymbol: input.stringValue,
                exchangeRate: wallet.latestEthExchangeRate
            )
            return value
        case .bitcoinCash:
            let value = NumberFormatter.parseBtcValue(from: input.stringValue)
            return NumberFormatter.formatBch(
                withSymbol: value.magnitude,
                localCurrency: true
            )
        case .stellar:
            // TODO: add formatting methods
            return "stellar in fiat"
        }
    }
    
    func toCrypto(
        amount: Decimal,
        from wallet: Wallet = WalletManager.shared.wallet
    ) -> String? {
        let input = amount as NSDecimalNumber
        switch self {
        case .bitcoin:
            let value = NumberFormatter.parseBtcValue(from: input.stringValue)
            return NumberFormatter.formatMoney(value.magnitude)
        case .ethereum:
            guard let exchangeRate = wallet.latestEthExchangeRate else { return nil }
            return NumberFormatter.formatEth(
                withLocalSymbol: input.stringValue,
                exchangeRate: exchangeRate
            )
        case .bitcoinCash:
            let value = NumberFormatter.parseBtcValue(from: input.stringValue)
            return NumberFormatter.formatBch(withSymbol: value.magnitude)
        case .stellar:
            // TODO: add formatting methods
            return "stellar in crypto"
        }
    }
}
