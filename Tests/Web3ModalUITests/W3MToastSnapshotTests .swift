import SnapshotTesting
import SwiftUI
@testable import Web3ModalUI
import XCTest

final class W3MToastSnapshotTests: XCTestCase {
    
    func test_snapshots() throws {
        let view = ToastViewPreviewView()
        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13), traits: .init(userInterfaceStyle: .dark)))
        assertSnapshot(matching: view, as: .image(layout: .device(config: .iPhone13), traits: .init(userInterfaceStyle: .light)))
    }
}
