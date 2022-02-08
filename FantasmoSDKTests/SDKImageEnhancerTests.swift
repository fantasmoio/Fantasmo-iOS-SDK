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
        let imageEnhancer = FantasmoSDK.FMImageEnhancer(targetBrightness: 0.15)!
        
        // test enhancement on daytime frame
        let daytimeSession = MockARSession(videoName: "parking-daytime")
        let daytimeFrame = daytimeSession.nextFrame()!
        imageEnhancer.enhance(frame: daytimeFrame)
        // check `enhancedImage` and `enhancedImage` properties were set
        XCTAssertNotNil(daytimeFrame.enhancedImage)
        XCTAssertNotNil(daytimeFrame.enhancedImageGamma)
        // check no gamma correction applied, daytime images exceed target brightness
        XCTAssertEqual(daytimeFrame.enhancedImageGamma!, 1.0)

        // test enhancement on nighttime frame
        let nighttimeSession = MockARSession(videoName: "parking-nighttime")
        let nighttimeFrame1 = nighttimeSession.nextFrame()!
        imageEnhancer.enhance(frame: nighttimeFrame1)
        // check `enhancedImage` and `enhancedImage` properties were set
        XCTAssertNotNil(nighttimeFrame1.enhancedImage)
        XCTAssertNotNil(nighttimeFrame1.enhancedImageGamma)
        // check gamma correction was applied
        XCTAssertLessThan(nighttimeFrame1.enhancedImageGamma!, 1.0)

        // test increasing target brightness
        let nighttimeFrame2 = nighttimeSession.nextFrame()!
        imageEnhancer.targetBrightness = 0.25
        imageEnhancer.enhance(frame: nighttimeFrame2)
        // check stronger (lower) gamma correction was used
        XCTAssertLessThan(nighttimeFrame2.enhancedImageGamma!, nighttimeFrame1.enhancedImageGamma!)
    }
}
