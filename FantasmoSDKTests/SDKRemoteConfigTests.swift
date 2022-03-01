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
        let frameEvaluatorChain = FMFrameEvaluatorChain(config: config)
        XCTAssertEqual(frameEvaluatorChain.filters.count, 1)

        let movementFilter = frameEvaluatorChain.getFilter(ofType: FMMovementFilter.self)
        XCTAssertNotNil(movementFilter)
        XCTAssertEqual(movementFilter!.threshold, config.movementFilterThreshold)
    }

    func testTrackingStateFilterConfig() throws {
        let config = getTestConfig("tracking-state-filter")!
        let frameEvaluatorChain = FMFrameEvaluatorChain(config: config)
        XCTAssertEqual(frameEvaluatorChain.filters.count, 1)

        let trackingStateFilter = frameEvaluatorChain.getFilter(ofType: FMTrackingStateFilter.self)
        XCTAssertNotNil(trackingStateFilter)
    }
    
    func testCameraPitchFilterConfig() throws {
        let config = getTestConfig("camera-pitch-filter")!
        let frameEvaluatorChain = FMFrameEvaluatorChain(config: config)
        XCTAssertEqual(frameEvaluatorChain.filters.count, 1)

        let cameraPitchFilter = frameEvaluatorChain.getFilter(ofType: FMCameraPitchFilter.self)
        XCTAssertNotNil(cameraPitchFilter)
        XCTAssertEqual(cameraPitchFilter!.maxUpwardTiltRadians, deg2rad(config.cameraPitchFilterMaxUpwardTilt))
        XCTAssertEqual(cameraPitchFilter!.maxDownwardTiltRadians, deg2rad(config.cameraPitchFilterMaxDownwardTilt))
    }
            
    func testImageEnhancerConfig() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "metal not supported")
        
        let config = getTestConfig("image-enhancer")!
        let frameEvaluatorChain = FMFrameEvaluatorChain(config: config)
        XCTAssertNotNil(frameEvaluatorChain.imageEnhancer)
        XCTAssertEqual(frameEvaluatorChain.imageEnhancer!.targetBrightness, config.imageEnhancerTargetBrightness)
    }
    
    func testImageEnhancerDisabledConfig() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "metal not supported")
        
        let config = getTestConfig("image-enhancer-disabled")!
        let frameEvaluatorChain = FMFrameEvaluatorChain(config: config)
        XCTAssertNil(frameEvaluatorChain.imageEnhancer)
    }
}
