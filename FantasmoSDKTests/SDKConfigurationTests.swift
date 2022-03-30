//
//  SDKConfigurationTests.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 30.03.22.
//

import XCTest
import FantasmoSDK

class SDKConfigurationTests: XCTestCase {
        
    func testAccessToken() throws {
        // check returns access token from Info.plist
        XCTAssertEqual(FMConfiguration.accessToken(), "a0fc7aa1e1144f1e81eaa2ad47794a9e")
        // check manually setting the access token overrides the one in Info.plist
        FMConfiguration.setAccessToken("new-access-token")
        XCTAssertEqual(FMConfiguration.accessToken(), "new-access-token")
    }
}
