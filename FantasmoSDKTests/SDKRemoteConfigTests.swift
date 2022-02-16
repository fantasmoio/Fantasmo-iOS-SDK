//
//  SDKRemoteConfigTests.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 30.11.21.
//

import XCTest
@testable import FantasmoSDK

class SDKRemoteConfigTests: XCTestCase {

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
    
    private func getTestConfig(_ name: String) -> RemoteConfig.Config? {
        let fileUrl = Bundle(for: SDKRemoteConfigTests.self).url(forResource: name, withExtension: "json")!
        return RemoteConfig.Config(from: fileUrl)
    }
        
    func testDefaultConfig() throws {
        let defaultFileUrl = Bundle(for: FMSDKInfo.self).url(forResource: "default-config", withExtension: "json")!
        let defaultConfig = RemoteConfig.Config(from: defaultFileUrl)
        XCTAssertNotNil(defaultConfig)
    }
    
    func testServerAddedNewConfigFields() throws {
        let config = getTestConfig("server-added-fields")!
        XCTAssertNotNil(config)
    }
    
    func testMovementFilterConfig() throws {
        let config = getTestConfig("movement-filter")!
        let filterChain = FMFrameFilterChain(config: config)
        XCTAssertEqual(filterChain.preImageEnhancementFilters.count, 1)
        XCTAssertEqual(filterChain.postImageEnhancementFilters.count, 0)

        let movementFilter = filterChain.getFilter(ofType: FMMovementFilter.self)
        XCTAssertNotNil(movementFilter)
        XCTAssertEqual(movementFilter!.threshold, config.movementFilterThreshold)
    }

    func testTrackingStateFilterConfig() throws {
        let config = getTestConfig("tracking-state-filter")!
        let filterChain = FMFrameFilterChain(config: config)
        XCTAssertEqual(filterChain.preImageEnhancementFilters.count, 1)
        XCTAssertEqual(filterChain.postImageEnhancementFilters.count, 0)

        let trackingStateFilter = filterChain.getFilter(ofType: FMTrackingStateFilter.self)
        XCTAssertNotNil(trackingStateFilter)
    }
    
    func testCameraPitchFilterConfig() throws {
        let config = getTestConfig("camera-pitch-filter")!
        let filterChain = FMFrameFilterChain(config: config)
        XCTAssertEqual(filterChain.preImageEnhancementFilters.count, 1)
        XCTAssertEqual(filterChain.postImageEnhancementFilters.count, 0)

        let cameraPitchFilter = filterChain.getFilter(ofType: FMCameraPitchFilter.self)
        XCTAssertNotNil(cameraPitchFilter)
        XCTAssertEqual(cameraPitchFilter!.maxUpwardTiltRadians, deg2rad(config.cameraPitchFilterMaxUpwardTilt))
        XCTAssertEqual(cameraPitchFilter!.maxDownwardTiltRadians, deg2rad(config.cameraPitchFilterMaxDownwardTilt))
    }
    
    func testBlurFilterConfig() throws {
        let config = getTestConfig("blur-filter")!
        let filterChain = FMFrameFilterChain(config: config)
        XCTAssertEqual(filterChain.preImageEnhancementFilters.count, 1)
        XCTAssertEqual(filterChain.postImageEnhancementFilters.count, 0)

        let blurFilter = filterChain.getFilter(ofType: FMBlurFilter.self)
        XCTAssertNotNil(blurFilter)
        XCTAssertEqual(blurFilter!.varianceThreshold, config.blurFilterVarianceThreshold)
        XCTAssertEqual(blurFilter!.suddenDropThreshold, config.blurFilterSuddenDropThreshold)
        XCTAssertEqual(blurFilter!.averageThroughputThreshold, config.blurFilterAverageThroughputThreshold)
    }
    
    func testImageQualityFilterConfig() throws {
        let config = getTestConfig("image-quality-filter")!
        let filterChain = FMFrameFilterChain(config: config)
        XCTAssertEqual(filterChain.preImageEnhancementFilters.count, 0)
        XCTAssertEqual(filterChain.postImageEnhancementFilters.count, 1)
        
        let imageQualityFilter = filterChain.getFilter(ofType: FMImageQualityFilter.self)
        XCTAssertNotNil(imageQualityFilter)
        XCTAssertEqual(imageQualityFilter!.scoreThreshold, config.imageQualityFilterScoreThreshold)
    }
    
    func testImageEnhancerConfig() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "metal not supported")
        
        let config = getTestConfig("image-enhancer")!
        let filterChain = FMFrameFilterChain(config: config)
        XCTAssertNotNil(filterChain.imageEnhancer)
        XCTAssertEqual(filterChain.imageEnhancer!.targetBrightness, config.imageEnhancerTargetBrightness)
    }
    
    func testImageEnhancerDisabledConfig() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "metal not supported")
        
        let config = getTestConfig("image-enhancer-disabled")!
        let filterChain = FMFrameFilterChain(config: config)
        XCTAssertNil(filterChain.imageEnhancer)
    }
}
