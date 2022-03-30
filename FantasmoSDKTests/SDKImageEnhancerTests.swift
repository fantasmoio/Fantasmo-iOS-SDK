//
//  SDKImageEnhancerTests.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 08.02.22.
//

import XCTest
@testable import FantasmoSDK

class SDKImageEnhancerTests: XCTestCase {
      
    func testComputeGamma() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "metal not supported")
        
        let imageEnhancer = try XCTUnwrap(FMImageEnhancer(targetBrightness: 0.50))
        
        // create an empty histogram buffer to work with
        let count = 5
        let histogramBins = UnsafeMutablePointer<UInt32>.allocate(capacity: count)
        histogramBins.initialize(repeating: 0, count: count)
        
        // add one 25% pixel
        histogramBins[1] = 1
        XCTAssertEqual(0.25, imageEnhancer.getAverageBrightness(histogramBins: histogramBins, count: count))
        
        // check gamma correction is needed since less than targetBrightness
        XCTAssertEqual(0.5, imageEnhancer.computeGamma(histogramBins: histogramBins, count: count))
        
        // add one 100% pixel
        histogramBins[count - 1] = 1
        XCTAssertEqual(0.625, imageEnhancer.getAverageBrightness(histogramBins: histogramBins, count: count))
        
        // check no gamma correction needed since above targetBrightness
        XCTAssertEqual(1.0, imageEnhancer.computeGamma(histogramBins: histogramBins, count: count))
    }
    
    func testGetAverageBrightness() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "metal not supported")
        
        let imageEnhancer = try XCTUnwrap(FMImageEnhancer(targetBrightness: 0.15))
        
        // create an empty histogram buffer to work with
        let count = 2
        let histogramBins = UnsafeMutablePointer<UInt32>.allocate(capacity: count)
        histogramBins.initialize(repeating: 0, count: count)
        
        // add one black pixel
        histogramBins[0] = 1
        // check the image is 0% brightness
        XCTAssertEqual(0.0, imageEnhancer.getAverageBrightness(histogramBins: histogramBins, count: count))
        
        // add one white pixel
        histogramBins[count - 1] = 1
        // check the image is now 50% brightness
        XCTAssertEqual(0.5, imageEnhancer.getAverageBrightness(histogramBins: histogramBins, count: count))
        
        // add two more white pixels
        histogramBins[count - 1] += 2
        // check average brightness is now 75%
        XCTAssertEqual(0.75, imageEnhancer.getAverageBrightness(histogramBins: histogramBins, count: count))
    }

    func testGetAverageBrightnessWithGamma() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "metal not supported")
        
        let imageEnhancer = try XCTUnwrap(FMImageEnhancer(targetBrightness: 0.15))
        
        // create an empty histogram buffer to work with
        let count = 10
        let histogramBins = UnsafeMutablePointer<UInt32>.allocate(capacity: count)
        
        // add a single pixel for each bin
        histogramBins.initialize(repeating: 1, count: count)
        
        // get reference brightness with gamma == 1.0
        let averageBrightness = imageEnhancer.getAverageBrightness(histogramBins: histogramBins, count: count, gamma: 1.0)
        
        // check the average brightness is higher with gamma < 1.0
        let averageBrightnessWithGammaLessThanOne = imageEnhancer.getAverageBrightness(
            histogramBins: histogramBins, count: count, gamma: 0.95)
        XCTAssertGreaterThan(averageBrightnessWithGammaLessThanOne, averageBrightness)
        
        // check the average brightness is lower with gamma > 1.0
        let averageBrightnessWithGammaGreaterThanOne = imageEnhancer.getAverageBrightness(
            histogramBins: histogramBins, count: count, gamma: 1.05)
        XCTAssertLessThan(averageBrightnessWithGammaGreaterThanOne, averageBrightness)
    }
    
    func testImageEnhancerNighttime() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "metal not supported")
        
        let imageEnhancer = try XCTUnwrap(FMImageEnhancer(targetBrightness: 0.15))
        let nighttimeSession = MockARSession(videoName: "parking-nighttime")
        
        let nighttimeFrame1 = try nighttimeSession.getNextFrame()
        imageEnhancer.enhance(frame: nighttimeFrame1)
        // check `enhancedImage` and `enhancedImage` properties were set
        XCTAssertNotNil(nighttimeFrame1.enhancedImage)
        
        // check gamma correction was applied
        let enhancedImageGamma1 = try XCTUnwrap(nighttimeFrame1.enhancedImageGamma)
        XCTAssertLessThan(enhancedImageGamma1, 1.0)

        // increase target brightness
        imageEnhancer.targetBrightness = 0.25
        
        let nighttimeFrame2 = try nighttimeSession.getNextFrame()
        imageEnhancer.enhance(frame: nighttimeFrame2)
        // check `enhancedImage` and `enhancedImage` properties were set
        XCTAssertNotNil(nighttimeFrame2.enhancedImage)

        // check stronger (lower) gamma correction was applied
        let enhancedImageGamma2 = try XCTUnwrap(nighttimeFrame2.enhancedImageGamma)
        XCTAssertLessThan(enhancedImageGamma2, enhancedImageGamma1)
    }
    
    func testImageEnhancerDaytime() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "metal not supported")
        
        let imageEnhancer = try XCTUnwrap(FMImageEnhancer(targetBrightness: 0.15))
        let daytimeSession = MockARSession(videoName: "parking-daytime")
                
        let daytimeFrame = try daytimeSession.getNextFrame()
        imageEnhancer.enhance(frame: daytimeFrame)
        // check no gamma correction applied, daytime images exceed target brightness
        XCTAssertNil(daytimeFrame.enhancedImage)
        XCTAssertNil(daytimeFrame.enhancedImageGamma)
    }
}
