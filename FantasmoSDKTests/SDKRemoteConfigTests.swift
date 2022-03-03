//
//  SDKRemoteConfigTests.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 30.11.21.
//

import XCTest
@testable import FantasmoSDK

class SDKRemoteConfigTests: XCTestCase {
    
    func testDefaultBundledConfig() throws {
        let defaultConfig = TestUtils.getDefaultConfig()
        XCTAssertNotNil(defaultConfig)
    }
    
    func testServerAddedNewConfigFields() throws {
        let config = TestUtils.getTestConfig("server-added-fields")!
        XCTAssertNotNil(config)
    }
}
