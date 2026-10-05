import Flutter
import UIKit
import XCTest
@testable import Runner

class RunnerTests: XCTestCase {

  func testSessionPersistsAcrossStoreInstancesAndLogoutRemovesIt() throws {
    let service = "com.teralume.energycore.tests.\(UUID().uuidString)"
    let store = KeychainTokenStore(service: service)
    defer { try? store.clear() }
    XCTAssertNil(try store.read())
    try store.write("synthetic-session-one")
    XCTAssertEqual(try KeychainTokenStore(service: service).read(), "synthetic-session-one")
    try store.write("synthetic-session-two")
    XCTAssertEqual(try store.read(), "synthetic-session-two")
    try store.clear()
    XCTAssertNil(try store.read())
    XCTAssertNoThrow(try store.clear())
  }

}
