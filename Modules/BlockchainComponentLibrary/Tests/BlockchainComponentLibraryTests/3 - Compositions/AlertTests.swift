@testable import BlockchainComponentLibrary
import SnapshotTesting
import SwiftUI
import XCTest

final class AlertTests: XCTestCase {

    func testSnapshot() {
        let view = Alert_Previews.previews
            .frame(width: 320)
            .fixedSize()

        assertSnapshot(matching: view, as: .image(layout: .sizeThatFits), record: false)
    }

    func testSnapshot_largeDevices() {
        let view = Alert_Previews.previews
            .frame(width: 1024)
            .fixedSize()

        assertSnapshot(matching: view, as: .image(layout: .sizeThatFits), record: false)
    }
}
