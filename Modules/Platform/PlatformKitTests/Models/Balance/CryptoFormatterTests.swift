// Copyright © Blockchain Luxembourg S.A. All rights reserved.

@testable import PlatformKit
import XCTest

// swiftlint:disable all
class CryptoFormatterTests: XCTestCase {
    private var englishLocale: Locale!
    private var btcFormatter: CryptoFormatter!
    private var ethFormatter: CryptoFormatter!
    private var bchFormatter: CryptoFormatter!
    private var xlmFormatter: CryptoFormatter!

    override func setUp() {
        super.setUp()
        englishLocale = Locale(identifier: "en_US")
        btcFormatter = CryptoFormatter(locale: englishLocale, cryptoCurrency: .bitcoin, minFractionDigits: 1)
        ethFormatter = CryptoFormatter(locale: englishLocale, cryptoCurrency: .ethereum, minFractionDigits: 1)
        bchFormatter = CryptoFormatter(locale: englishLocale, cryptoCurrency: .bitcoinCash, minFractionDigits: 1)
        xlmFormatter = CryptoFormatter(locale: englishLocale, cryptoCurrency: .stellar, minFractionDigits: 1)
    }

    func testFormatWithoutSymbolBtc() {
        XCTAssertEqual(
            "0.00000001",
            btcFormatter.format(value: CryptoValue(amount: 1, currency: .bitcoin))
        )
        XCTAssertEqual(
            "0.1",
            btcFormatter.format(value: CryptoValue.create(major: "0.1", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "0.0",
            btcFormatter.format(value: CryptoValue.create(major: "0", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "1.0",
            btcFormatter.format(value: CryptoValue.create(major: "1", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "1,000.0",
            btcFormatter.format(value: CryptoValue.create(major: "1000", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "1,000,000.0",
            btcFormatter.format(value: CryptoValue.create(major: "1000000", currency: .bitcoin)!)
        )
    }

    func testFormatWithSymbolBtc() {
        XCTAssertEqual(
            "0.00000001 BTC",
            btcFormatter.format(value: CryptoValue(amount: 1, currency: .bitcoin), withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.1 BTC",
            btcFormatter.format(value: CryptoValue.create(major: "0.1", currency: .bitcoin)!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.0 BTC",
            btcFormatter.format(value: CryptoValue.create(major: "0", currency: .bitcoin)!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "1.0 BTC",
            btcFormatter.format(value: CryptoValue.create(major: "1", currency: .bitcoin)!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "1,000.0 BTC",
            btcFormatter.format(value: CryptoValue.create(major: "1000", currency: .bitcoin)!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "1,000,000.0 BTC",
            btcFormatter.format(value: CryptoValue.create(major: "1000000", currency: .bitcoin)!, withPrecision: .short, includeSymbol: true)
        )
    }

    func testFormatEthShortPrecision() {
        XCTAssertEqual(
            "0.0 ETH",
            ethFormatter.format(value: CryptoValue(amount: 1, currency: .ethereum), withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.0 ETH",
            ethFormatter.format(value: CryptoValue(amount: 1000, currency: .ethereum), withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.0 ETH",
            ethFormatter.format(value: CryptoValue(amount: 1000000, currency: .ethereum), withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.0 ETH",
            ethFormatter.format(value: CryptoValue(amount: 1000000000, currency: .ethereum), withPrecision: .short, includeSymbol: true)
        )
    }

    func testFormatEthLongPrecision() {
        XCTAssertEqual(
            "0.000000000000000001 ETH",
            ethFormatter.format(value: CryptoValue(amount: 1, currency: .ethereum), withPrecision: .long, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.000000000000001 ETH",
            ethFormatter.format(value: CryptoValue(amount: 1000, currency: .ethereum), withPrecision: .long, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.000000000001 ETH",
            ethFormatter.format(value: CryptoValue(amount: 1000000, currency: .ethereum), withPrecision: .long, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.000000001 ETH",
            ethFormatter.format(value: CryptoValue(amount: 1000000000, currency: .ethereum), withPrecision: .long, includeSymbol: true)
        )
    }

    func testFormatWithoutSymbolEth() {
        XCTAssertEqual(
            "0.00000001",
            ethFormatter.format(value: CryptoValue.create(minor: "10000000000", currency: .ethereum))
        )
        XCTAssertEqual(
            "0.00001",
            ethFormatter.format(value: CryptoValue.create(minor: "10000000000000", currency: .ethereum))
        )
        XCTAssertEqual(
            "0.1",
            ethFormatter.format(value: CryptoValue.create(minor: "100000000000000000", currency: .ethereum))
        )
        XCTAssertEqual(
            "1.0",
            ethFormatter.format(value: CryptoValue.create(minor: "1000000000000000000", currency: .ethereum))
        )
        XCTAssertEqual(
            "10.0",
            ethFormatter.format(value: CryptoValue.create(minor: "10000000000000000000", currency: .ethereum))
        )
        XCTAssertEqual(
            "100.0",
            ethFormatter.format(value: CryptoValue.create(minor: "100000000000000000000", currency: .ethereum))
        )
        XCTAssertEqual(
            "1,000.0",
            ethFormatter.format(value: CryptoValue.create(minor: "1000000000000000000000", currency: .ethereum))
        )
        XCTAssertEqual(
            "1.213333",
            ethFormatter.format(value: CryptoValue.create(major: "1.213333", currency: .ethereum)!)
        )
        XCTAssertEqual(
            "1.12345678",
            ethFormatter.format(value: CryptoValue.create(major: "1.123456789", currency: .ethereum)!)
        )
    }

    func testFormatWithSymbolEth() {
        XCTAssertEqual(
            "0.00000001 ETH",
            ethFormatter.format(value: CryptoValue.create(minor: "10000000000", currency: .ethereum), withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.00001 ETH",
            ethFormatter.format(value: CryptoValue.create(minor: "10000000000000", currency: .ethereum), withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.1 ETH",
            ethFormatter.format(value: CryptoValue.create(minor: "100000000000000000", currency: .ethereum), withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "1.213333 ETH",
            ethFormatter.format(value: CryptoValue.create(major: "1.213333", currency: .ethereum)!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "1.12345678 ETH",
            ethFormatter.format(value: CryptoValue.create(major: "1.123456789", currency: .ethereum)!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "1.12345678 ETH",
            ethFormatter.format(value: CryptoValue.create(minor: "1123456789333222111", currency: .ethereum), withPrecision: .short, includeSymbol: true)
        )
    }

    func testFormatWithoutSymbolBch() {
        XCTAssertEqual(
            "0.00000001",
            bchFormatter.format(value: CryptoValue(amount: 1, currency: .bitcoin))
        )
        XCTAssertEqual(
            "0.1",
            bchFormatter.format(value: CryptoValue.create(major: "0.1", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "0.0",
            bchFormatter.format(value: CryptoValue.create(major: "0", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "1.0",
            bchFormatter.format(value: CryptoValue.create(major: "1", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "1,000.0",
            bchFormatter.format(value: CryptoValue.create(major: "1000", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "1,000,000.0",
            bchFormatter.format(value: CryptoValue.create(major: "1000000", currency: .bitcoin)!)
        )
    }

    func testFormatWithSymbolBch() {
        XCTAssertEqual(
            "0.00000001 BCH",
            bchFormatter.format(value: CryptoValue(amount: 1, currency: .bitcoinCash), withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.1 BCH",
            bchFormatter.format(value: CryptoValue.create(major: "0.1", currency: .bitcoinCash)!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.0 BCH",
            bchFormatter.format(value: CryptoValue.create(major: "0", currency: .bitcoinCash)!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "1.0 BCH",
            bchFormatter.format(value: CryptoValue.create(major: "1", currency: .bitcoinCash)!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "1,000.0 BCH",
            bchFormatter.format(value: CryptoValue.create(major: "1000", currency: .bitcoinCash)!, withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "1,000,000.0 BCH",
            bchFormatter.format(value: CryptoValue.create(major: "1000000", currency: .bitcoinCash)!, withPrecision: .short, includeSymbol: true)
        )
    }

    func testFormatWithoutSymbolXlm() {
        XCTAssertEqual(
            "0.0000001",
            xlmFormatter.format(value: CryptoValue(amount: 1, currency: .stellar))
        )
        XCTAssertEqual(
            "0.1",
            xlmFormatter.format(value: CryptoValue.create(major: "0.1", currency: .stellar)!)
        )
        XCTAssertEqual(
            "0.0",
            xlmFormatter.format(value: CryptoValue.create(major: "0", currency: .stellar)!)
        )
        XCTAssertEqual(
            "1.0",
            xlmFormatter.format(value: CryptoValue.create(major: "1", currency: .stellar)!)
        )
        XCTAssertEqual(
            "1,000.0",
            xlmFormatter.format(value: CryptoValue.create(major: 1000, currency: .stellar))
        )
        XCTAssertEqual(
            "1,000,000.0",
            xlmFormatter.format(value: CryptoValue.create(major: 1000000, currency: .stellar))
        )
    }

    func testFormatWithSymbolXlm() {
        XCTAssertEqual(
            "0.0000001 XLM",
            xlmFormatter.format(value: CryptoValue(amount: 1, currency: .stellar), withPrecision: .short, includeSymbol: true)
        )
        XCTAssertEqual(
            "0.1 XLM",
            xlmFormatter.format(
                value: CryptoValue.create(major: "0.1", currency: .stellar)!,
                withPrecision: .short,
                includeSymbol: true
            )
        )
        XCTAssertEqual(
            "0.0 XLM",
            xlmFormatter.format(
                value: CryptoValue.create(major: "0", currency: .stellar)!,
                withPrecision: .short,
                includeSymbol: true
            )
        )
        XCTAssertEqual(
            "1.0 XLM",
            xlmFormatter.format(
                value: CryptoValue.create(major: "1", currency: .stellar)!,
                withPrecision: .short,
                includeSymbol: true
            )
        )
        XCTAssertEqual(
            "1,000.0 XLM",
            xlmFormatter.format(
                value: CryptoValue.create(major: 1000, currency: .stellar),
                withPrecision: .short,
                includeSymbol: true
            )
        )
        XCTAssertEqual(
            "1,000,000.0 XLM",
            xlmFormatter.format(
                value: CryptoValue.create(major: 1000000, currency: .stellar),
                withPrecision: .short,
                includeSymbol: true
            )
        )
    }

    func testItalyLocaleFormattingBtc() {
        let italyLocale = Locale(identifier: "it_IT")
        let formatter = CryptoFormatter(locale: italyLocale, cryptoCurrency: .bitcoin, minFractionDigits: 1)
        XCTAssertEqual(
            "0,00000001",
            formatter.format(value: CryptoValue(amount: 1, currency: .bitcoin))
        )
        XCTAssertEqual(
            "0,1",
            formatter.format(value: CryptoValue.create(major: "0.1", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "0,0",
            formatter.format(value: CryptoValue.create(major: "0", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "1,0",
            formatter.format(value: CryptoValue.create(major: "1", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "1.000,0",
            formatter.format(value: CryptoValue.create(major: "1000", currency: .bitcoin)!)
        )
        XCTAssertEqual(
            "1.000.000,0",
            formatter.format(value: CryptoValue.create(major: "1000000", currency: .bitcoin)!)
        )
    }
}
