//
//  SDKFilterConfigTests.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 30.11.21.
//

import XCTest
@testable import FantasmoSDK

class SDKFilterConfigTests: XCTestCase {

    override class func setUp() {
        // Put setup code here that is run once (equal to mocha "before" hook)
    }

    override func setUpWithError() throws {
        // Put setup code here is run before each test (equal to mocha "beforeEach" hook)
    }

    override func tearDownWithError() throws {
        // Put teardown code that is run after each test case (equal to mocha "afterEach" hook)
    }

    override class func tearDown() {
        // Put teardown code that is run once (equal to mocha "after" hook)
    }
        
    func getTestConfig(_ name: String) -> FantasmoSDK.RemoteConfig.Config {
        let fileUrl = Bundle(for: SDKFilterConfigTests.self).url(forResource: name, withExtension: "json")!
        return FantasmoSDK.RemoteConfig.Config(from: fileUrl)!
    }
    
    func testMovementFilterConfig() throws {
        let config = getTestConfig("movement-filter")
        let filterChain = FMFrameFilterChain(config: config)
        XCTAssertEqual(filterChain.filters.count, 1)
        
        let movementFilter = filterChain.filters.first as! FantasmoSDK.FMMovementFilter
        XCTAssertEqual(movementFilter.threshold, config.movementFilterThreshold)
    }

    func testTrackingStateFilterConfig() throws {
        let config = getTestConfig("tracking-state-filter")
        let filterChain = FMFrameFilterChain(config: config)
        XCTAssertEqual(filterChain.filters.count, 1)
        
        let trackingStateFilter = filterChain.filters.first as? FantasmoSDK.FMTrackingStateFilter
        XCTAssertNotNil(trackingStateFilter)
    }
    
    func testCameraPitchFilterConfig() throws {
        let config = getTestConfig("camera-pitch-filter")
        let filterChain = FMFrameFilterChain(config: config)
        XCTAssertEqual(filterChain.filters.count, 1)
        
        let cameraPitchFilter = filterChain.filters.first as! FantasmoSDK.FMCameraPitchFilter
        XCTAssertEqual(cameraPitchFilter.maxUpwardTiltRadians, deg2rad(config.cameraPitchFilterMaxUpwardTilt))
        XCTAssertEqual(cameraPitchFilter.maxDownwardTiltRadians, deg2rad(config.cameraPitchFilterMaxDownwardTilt))
    }
    
    func testBlurFilterConfig() throws {
        let config = getTestConfig("blur-filter")
        let filterChain = FMFrameFilterChain(config: config)
        XCTAssertEqual(filterChain.filters.count, 1)
        
        let blurFilter = filterChain.filters.first as! FantasmoSDK.FMBlurFilter
        XCTAssertEqual(blurFilter.varianceThreshold, config.blurFilterVarianceThreshold)
        XCTAssertEqual(blurFilter.suddenDropThreshold, config.blurFilterSuddenDropThreshold)
        XCTAssertEqual(blurFilter.averageThroughputThreshold, config.blurFilterAverageThroughputThreshold)
    }
    
    func testImageQualityFilterConfig() throws {
        let config = getTestConfig("image-quality-filter")
        let filterChain = FMFrameFilterChain(config: config)
        XCTAssertEqual(filterChain.filters.count, 1)
        
        let imageQualityFilter = filterChain.filters.first as! FantasmoSDK.FMImageQualityFilter
        XCTAssertEqual(imageQualityFilter.scoreThreshold, config.imageQualityFilterScoreThreshold)
    }

    func testImageEnhancerConfig() throws {
        let config = getTestConfig("image-enhancer")
        let filterChain = FMFrameFilterChain(config: config)
        XCTAssertNotNil(filterChain.imageEnhancer)
        XCTAssertEqual(filterChain.imageEnhancer!.targetBrightness, config.imageEnhancerTargetBrightness)
    }
    
    func testImageEnhancerDisabledConfig() throws {
        let config = getTestConfig("image-enhancer-disabled")
        let filterChain = FMFrameFilterChain(config: config)
        XCTAssertNil(filterChain.imageEnhancer)
    }
}
