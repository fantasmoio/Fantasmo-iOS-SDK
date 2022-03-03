//
//  SDKImageEnhancerTests.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 08.02.22.
//

import XCTest
@testable import FantasmoSDK

class SDKImageEnhancerTests: XCTestCase {
        
    func testImageEnhancerNighttime() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "metal not supported")
        
        let imageEnhancer = FMImageEnhancer(targetBrightness: 0.15)!
        let nighttimeSession = MockARSession(videoName: "parking-nighttime")
        
        let nighttimeFrame1 = try nighttimeSession.getNextFrame()
        imageEnhancer.enhance(frame: nighttimeFrame1)
        // check `enhancedImage` and `enhancedImage` properties were set
        XCTAssertNotNil(nighttimeFrame1.enhancedImage)
        XCTAssertNotNil(nighttimeFrame1.enhancedImageGamma)
        // check gamma correction was applied
        XCTAssertLessThan(nighttimeFrame1.enhancedImageGamma!, 1.0)

        // increase target brightness
        imageEnhancer.targetBrightness = 0.25
        
        let nighttimeFrame2 = try nighttimeSession.getNextFrame()
        imageEnhancer.enhance(frame: nighttimeFrame2)
        // check `enhancedImage` and `enhancedImage` properties were set
        XCTAssertNotNil(nighttimeFrame2.enhancedImage)
        XCTAssertNotNil(nighttimeFrame2.enhancedImageGamma)
        // check stronger (lower) gamma correction was applied
        XCTAssertLessThan(nighttimeFrame2.enhancedImageGamma!, nighttimeFrame1.enhancedImageGamma!)
    }
    
    func testImageEnhancerDaytime() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "metal not supported")
        
        let imageEnhancer = FMImageEnhancer(targetBrightness: 0.15)!
        let daytimeSession = MockARSession(videoName: "parking-daytime")
                
        let daytimeFrame = try daytimeSession.getNextFrame()
        imageEnhancer.enhance(frame: daytimeFrame)
        // check no gamma correction applied, daytime images exceed target brightness
        XCTAssertNil(daytimeFrame.enhancedImage)
        XCTAssertNil(daytimeFrame.enhancedImageGamma)
    }
}
