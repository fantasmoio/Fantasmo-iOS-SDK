//
//  SDKImageEnhancerTests.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 08.02.22.
//

import XCTest
@testable import FantasmoSDK

class SDKImageEnhancerTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testImageEnhancer() throws {
        let imageEnhancer = FantasmoSDK.FMImageEnhancer()!
        let nighttimeSession = MockARSession(videoName: "parking-nighttime")
        
        let nighttimeFrame1 = nighttimeSession.nextFrame()!
        imageEnhancer.enhance(nighttimeFrame1, targetAverageBrightness: 0.15)
        // check `enhancedImage` and `enhancedImage` properties were set
        XCTAssertNotNil(nighttimeFrame1.enhancedImage)
        XCTAssertNotNil(nighttimeFrame1.enhancedImageGamma)
        // check gamma correction was applied
        XCTAssertLessThan(nighttimeFrame1.enhancedImageGamma!, 1.0)

        let nighttimeFrame2 = nighttimeSession.nextFrame()!
        imageEnhancer.enhance(nighttimeFrame2, targetAverageBrightness: 0.25)
        // check stronger (lower) gamma correction used with a higher target brightness
        XCTAssertLessThan(nighttimeFrame2.enhancedImageGamma!, nighttimeFrame1.enhancedImageGamma!)
    }
}
