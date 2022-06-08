//
//  SDKFrameEvaluatorChainTests.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 02.03.22.
//

import XCTest
import CoreLocation
import ARKit
@testable import FantasmoSDK


class SDKFrameEvaluatorChainTests: XCTestCase {
    
    override class func setUp() {
        // Tests are based on the latest bundled model
        ImageQualityModel.removeDownloadedModel()
    }
    
    override class func tearDown() {
        ImageQualityModel.removeDownloadedModel()
    }
        
    func testFrameEvaluatorChainConfig() throws {
        let config = try XCTUnwrap(TestUtils.getDefaultConfig())
        let frameEvaluatorChain = FMFrameEvaluatorChain(config: config)
        
        // check score and window params were set
        XCTAssertEqual(frameEvaluatorChain.minScoreThreshold, config.minFrameEvaluationScore)
        XCTAssertEqual(frameEvaluatorChain.minHighQualityScore, config.minFrameEvaluationHighQualityScore)
        XCTAssertEqual(frameEvaluatorChain.minWindowTime, config.minLocalizationWindowTime)
        XCTAssertEqual(frameEvaluatorChain.maxWindowTime, config.maxLocalizationWindowTime)
        
        // check enabled filters are available
        XCTAssertEqual(config.isTrackingStateFilterEnabled, frameEvaluatorChain.getFilter(ofType: FMTrackingStateFilter.self) != nil)
        XCTAssertEqual(config.isCameraPitchFilterEnabled, frameEvaluatorChain.getFilter(ofType: FMCameraPitchFilter.self) != nil)
        XCTAssertEqual(config.isMovementFilterEnabled, frameEvaluatorChain.getFilter(ofType: FMMovementFilter.self) != nil)
        
        // check image enhancer is enabled/disabled
        let metalSupported = MTLCreateSystemDefaultDevice() != nil
        XCTAssertEqual(config.isImageEnhancerEnabled && metalSupported, frameEvaluatorChain.imageEnhancer != nil)
    }
    
    func testReturnsBestFrame() throws {
        // initialize a mock session and evaluator chain
        let mockSession = MockARSession(videoName: "parking-daytime")
        let (frameEvaluatorChain, delegate) = TestUtils.makeFrameEvaluatorChainAndDelegate()
        
        // expect that we'll evaluate exactly n frames
        var frameIndex = 0
        let framesToEvaluate = try mockSession.getFrameSequence(length: 3)
        let frameEvaluated = expectation(description: "frame evaluated")
        frameEvaluated.expectedFulfillmentCount = framesToEvaluate.count
        frameEvaluated.assertForOverFulfill = true
        
        // expect at least one frame will be the new best and our delegate method will be called
        let newBestFrameCalled = expectation(description: "newBestFrame delegate method called")
        newBestFrameCalled.assertForOverFulfill = false
        
        // adjust window times so we can easily test between them
        frameEvaluatorChain.minWindowTime = 1.0
        frameEvaluatorChain.maxWindowTime = 2.0
        
        delegate.didFinishEvaluatingFrame = { frame in
            guard let evaluation = frame.evaluation else {
                return
            }
            // check the evaluation is valid
            XCTAssertGreaterThan(evaluation.score, 0.0)
            XCTAssertLessThan(evaluation.score, frameEvaluatorChain.minHighQualityScore)
            XCTAssertEqual(evaluation.type, .imageQuality)
            XCTAssertNotNil(evaluation.imageQualityUserInfo)
            // finished evaluating a frame, increment the fulfillment count
            frameEvaluated.fulfill()
            // evaluate the next frame, if any
            frameIndex += 1
            if frameIndex < framesToEvaluate.count {
                frameEvaluatorChain.evaluateAsync(frame: framesToEvaluate[frameIndex])
            }
        }
        delegate.didEvaluateNewBestFrame = { frame in
            newBestFrameCalled.fulfill()
        }
        
        // evaluate the first frame and wait
        frameEvaluatorChain.evaluateAsync(frame: framesToEvaluate[0])
        wait(for: [frameEvaluated, newBestFrameCalled], timeout: 5.0)
        
        // check we are currently before the min window
        let minWindow = frameEvaluatorChain.getMinWindow()
        XCTAssertTrue(Date() < minWindow)
        
        // check that no frame is returned before the min window
        XCTAssertNil(frameEvaluatorChain.dequeueBestFrame())
        
        // wait until the min window
        let timeUntilMinWindow = minWindow.timeIntervalSince(Date())
        _ = XCTWaiter.wait(for: [expectation(description: "")], timeout: timeUntilMinWindow)
        
        // check we are currently between the min and max window
        let maxWindow = frameEvaluatorChain.getMaxWindow()
        XCTAssertTrue(Date() > minWindow && Date() < maxWindow)
        
        // check that no frame is returned before the max window
        XCTAssertNil(frameEvaluatorChain.dequeueBestFrame())
        
        // wait until the max window
        let timeUntilMaxWindow = maxWindow.timeIntervalSince(Date())
        _ = XCTWaiter.wait(for: [expectation(description: "")], timeout: timeUntilMaxWindow)
        
        // check the best frame is now returned
        let frameWithBestScore = framesToEvaluate.max { $0.evaluation!.score < $1.evaluation!.score }
        let frameDequeued = try XCTUnwrap(frameEvaluatorChain.dequeueBestFrame())
        XCTAssertTrue(frameDequeued === frameWithBestScore)
        
        // check a second dequeue does not return anything
        XCTAssertNil(frameEvaluatorChain.dequeueBestFrame())
        
        // check the window was reset
        XCTAssertNil(frameEvaluatorChain.currentBestFrame)
        XCTAssertTrue(frameEvaluatorChain.getMaxWindow() > maxWindow)
    }
    
    func testReturnsHighQualityFrameEarlier() throws {
        // initialize a mock session and evaluator chain
        let mockSession = MockARSession(videoName: "parking-daytime")
        let (frameEvaluatorChain, delegate) = TestUtils.makeFrameEvaluatorChainAndDelegate()

        // expect that we will evaluate a high quality frame
        let highQualityFrameEvaluated = expectation(description: "high quality frame evaluated")
        
        // expect this frame will be the new best and our delegate method will be called
        let newBestFrameCalled = expectation(description: "newBestFrame delegate method called")
        newBestFrameCalled.assertForOverFulfill = false
        
        // reduce the min high-quality score, our test frames should score above this
        frameEvaluatorChain.minHighQualityScore = 0.5
        
        // adjust window times so we can easily test between them
        frameEvaluatorChain.minWindowTime = 1.0
        frameEvaluatorChain.maxWindowTime = 2.0
        frameEvaluatorChain.resetWindow()
        
        delegate.didFinishEvaluatingFrame = { frame in
            guard let evaluation = frame.evaluation else {
                return
            }
            // check the evaluation is valid
            XCTAssertGreaterThanOrEqual(evaluation.score, frameEvaluatorChain.minHighQualityScore)
            XCTAssertLessThan(evaluation.score, 1.0)
            highQualityFrameEvaluated.fulfill()
        }
        delegate.didEvaluateNewBestFrame = { _ in
            newBestFrameCalled.fulfill()
        }
        
        // wait for the high quality frame to be evaluated
        let highQualityFrame = try mockSession.getNextFrame()
        frameEvaluatorChain.evaluateAsync(frame: highQualityFrame)
        wait(for: [highQualityFrameEvaluated, newBestFrameCalled], timeout: 5.0)
        
        // check we are currently before the min window
        let minWindow = frameEvaluatorChain.getMinWindow()
        XCTAssertTrue(Date() < minWindow)
        
        // check the high quality frame is not returned before the min window
        XCTAssertNil(frameEvaluatorChain.dequeueBestFrame())
        
        // wait until the min window
        let timeUntilMinWindow = minWindow.timeIntervalSince(Date())
        _ = XCTWaiter.wait(for: [expectation(description: "")], timeout: timeUntilMinWindow)
        
        // check we are currently between the min and max window
        XCTAssertTrue(Date() > minWindow && Date() < frameEvaluatorChain.getMaxWindow())
        
        // check the high quality frame was returned after the min window but before the max window
        let bestFrame = try XCTUnwrap(frameEvaluatorChain.dequeueBestFrame())
        XCTAssertTrue(bestFrame === highQualityFrame)
    }
    
    func testRejectsFrameBelowMinScoreThreshold() throws {
        // initialize a mock session and evaluator chain
        let mockSession = MockARSession(videoName: "parking-daytime")
        let (frameEvaluatorChain, delegate) = TestUtils.makeFrameEvaluatorChainAndDelegate()

        // expect that we will evaluate a low quality frame and our delegate method will be called
        let frameEvaluated = expectation(description: "frame evaluated")
        let frameRejectedBelowMinScoreThreshold = expectation(description: "frame rejected below min score threshold")
                
        // increase the min score threshold, our test frames should score below this
        frameEvaluatorChain.minScoreThreshold = 0.8
        delegate.didFinishEvaluatingFrame = { frame in
            guard let evaluation = frame.evaluation else {
                return
            }
            XCTAssertLessThan(evaluation.score, frameEvaluatorChain.minScoreThreshold)
            frameEvaluated.fulfill()
        }
        delegate.didRejectFrame = { frame, reason in
            if reason == .scoreBelowMinThreshold {
                frameRejectedBelowMinScoreThreshold.fulfill()
            }
        }
        
        // wait for the low quality frame to be evaluated
        let lowQualityFrame = try mockSession.getNextFrame()
        frameEvaluatorChain.evaluateAsync(frame: lowQualityFrame)
        wait(for: [frameEvaluated, frameRejectedBelowMinScoreThreshold], timeout: 3.0)
        
        // wait until the max window
        let maxWindow = frameEvaluatorChain.getMaxWindow()
        let timeUntilMaxWindow = maxWindow.timeIntervalSince(Date())
        _ = XCTWaiter.wait(for: [expectation(description: "")], timeout: timeUntilMaxWindow)
        
        // check the low quality frame is _not_ returned
        XCTAssertNil(frameEvaluatorChain.dequeueBestFrame())
        
        // check the window was _not_ reset
        XCTAssertEqual(maxWindow, frameEvaluatorChain.getMaxWindow())
    }
    
    func testRejectsFrameWhileEvaluatingAnotherFrame() throws {
        // initialize a mock session and evaluator chain
        let mockSession = MockARSession(videoName: "parking-daytime")
        let (frameEvaluatorChain, delegate) = TestUtils.makeFrameEvaluatorChainAndDelegate()

        // expect exactly one frame to be evaluated
        let frameEvaluated = expectation(description: "frame evaluated")
        frameEvaluated.expectedFulfillmentCount = 1
        frameEvaluated.assertForOverFulfill = true
        
        // expect exactly one frame to be rejected
        let frameRejected = expectation(description: "frame rejected other evaluation in progress")
        frameRejected.expectedFulfillmentCount = 1
        frameRejected.assertForOverFulfill = true
        
        let firstFrame = try mockSession.getNextFrame()
        let secondFrame = try mockSession.getNextFrame()
        
        delegate.didFinishEvaluatingFrame = { frame in
            frameEvaluated.fulfill()
            // check first frame was evaluated
            XCTAssertTrue(frame === firstFrame)
        }
        delegate.didRejectFrame = { frame, reason in
            if reason == .otherEvaluationInProgress {
                frameRejected.fulfill()
            }
        }
        
        // evaluate the two frames and wait
        frameEvaluatorChain.evaluateAsync(frame: firstFrame)
        frameEvaluatorChain.evaluateAsync(frame: secondFrame)
        wait(for: [frameEvaluated, frameRejected], timeout: 5.0)
    }
                        
    // MARK: - Filters
    
    func testMovementFilterConfigured() throws {
        let config = TestUtils.getTestConfig("movement-filter")!
        let frameEvaluatorChain = FMFrameEvaluatorChain(config: config)
        XCTAssertEqual(frameEvaluatorChain.filters.count, 1)

        let movementFilter = frameEvaluatorChain.getFilter(ofType: FMMovementFilter.self)
        XCTAssertNotNil(movementFilter)
        XCTAssertEqual(movementFilter!.threshold, config.movementFilterThreshold)
    }
    
    func testMovementFilterRejectsFrame() throws {
        let mockSession = MockARSession(videoName: "parking-daytime")
        let firstFrame = try mockSession.getNextFrame(MockCamera(transform: simd_float4x4(1)))
        let secondFrame = try mockSession.getNextFrame(MockCamera(transform: simd_float4x4(1.1)))
        
        let firstFrameRejected = expectation(description: "first frame rejected by movement filter")
        let secondFrameRejected = expectation(description: "second frame rejected by movement filter")
        secondFrameRejected.isInverted = true  // second frame should _not_ be rejected
        
        let (frameEvaluatorChain, delegate) = TestUtils.makeFrameEvaluatorChainAndDelegate()
        XCTAssertEqual(frameEvaluatorChain.filters.count, 3)
        delegate.didRejectFrameWithFilter = { rejectedFrame, filter, reason in
            guard type(of: filter) == FMMovementFilter.self else {
                return
            }
            if firstFrame === rejectedFrame, reason == .movingTooLittle {
                firstFrameRejected.fulfill()
            }
            if secondFrame === rejectedFrame {
                secondFrameRejected.fulfill()
            }
        }
        
        frameEvaluatorChain.evaluateAsync(frame: firstFrame)
        frameEvaluatorChain.evaluateAsync(frame: secondFrame)
        
        wait(for: [firstFrameRejected, secondFrameRejected], timeout: 0.0)
    }
    
    func testCameraPitchFilterConfigured() throws {
        let config = TestUtils.getTestConfig("camera-pitch-filter")!
        let frameEvaluatorChain = FMFrameEvaluatorChain(config: config)
        XCTAssertEqual(frameEvaluatorChain.filters.count, 1)

        let cameraPitchFilter = frameEvaluatorChain.getFilter(ofType: FMCameraPitchFilter.self)
        XCTAssertNotNil(cameraPitchFilter)
        XCTAssertEqual(cameraPitchFilter!.maxUpwardTiltRadians, deg2rad(config.cameraPitchFilterMaxUpwardTilt))
        XCTAssertEqual(cameraPitchFilter!.maxDownwardTiltRadians, deg2rad(config.cameraPitchFilterMaxDownwardTilt))
    }
    
    func testCameraPitchFilterRejectsFrame() throws {
        let mockSession = MockARSession(videoName: "parking-daytime")
        let tooLowFrame = try mockSession.getNextFrame(MockCamera(pitch: deg2rad(-70)))
        let tooHighFrame = try mockSession.getNextFrame(MockCamera(pitch: deg2rad(35)))
        let goodFrame = try mockSession.getNextFrame(MockCamera(pitch: deg2rad(10)))
        
        let tooLowFrameRejected = expectation(description: "too-low frame rejected by camera pitch filter")
        let tooHighFrameRejected = expectation(description: "too-high frame rejected by camera pitch filter")
        let goodFrameRejected = expectation(description: "good frame rejected by camera pitch filter")
        goodFrameRejected.isInverted = true  // good frame should _not_ be rejected
        
        let (frameEvaluatorChain, delegate) = TestUtils.makeFrameEvaluatorChainAndDelegate()
        XCTAssertEqual(frameEvaluatorChain.filters.count, 3)
        delegate.didRejectFrameWithFilter = { rejectedFrame, filter, reason in
            guard type(of: filter) == FMCameraPitchFilter.self else {
                return
            }
            if tooLowFrame === rejectedFrame, reason == .pitchTooLow {
                tooLowFrameRejected.fulfill()
            }
            if tooHighFrame === rejectedFrame, reason == .pitchTooHigh {
                tooHighFrameRejected.fulfill()
            }
            if goodFrame === rejectedFrame {
                goodFrameRejected.fulfill()
            }
        }
        
        frameEvaluatorChain.evaluateAsync(frame: tooLowFrame)
        frameEvaluatorChain.evaluateAsync(frame: tooHighFrame)
        frameEvaluatorChain.evaluateAsync(frame: goodFrame)
        
        wait(for: [tooLowFrameRejected, tooHighFrameRejected, goodFrameRejected], timeout: 0.0)
    }
    
    func testTrackingStateFilterConfigured() throws {
        let config = TestUtils.getTestConfig("tracking-state-filter")!
        let frameEvaluatorChain = FMFrameEvaluatorChain(config: config)
        XCTAssertEqual(frameEvaluatorChain.filters.count, 1)

        let trackingStateFilter = frameEvaluatorChain.getFilter(ofType: FMTrackingStateFilter.self)
        XCTAssertNotNil(trackingStateFilter)
    }
    
    func testTrackingStateFilterRejectsFrame() throws {
        let mockSession = MockARSession(videoName: "parking-daytime")
        let notAvailableFrame = try mockSession.getNextFrame(MockCamera(trackingState: .notAvailable))
        let limitedFrame1 = try mockSession.getNextFrame(MockCamera(trackingState: .limited(.initializing)))
        let limitedFrame2 = try mockSession.getNextFrame(MockCamera(trackingState: .limited(.relocalizing)))
        let limitedFrame3 = try mockSession.getNextFrame(MockCamera(trackingState: .limited(.excessiveMotion)))
        let limitedFrame4 = try mockSession.getNextFrame(MockCamera(trackingState: .limited(.insufficientFeatures)))
        let normalFrame = try mockSession.getNextFrame(MockCamera(trackingState: .normal))
                
        let badFrameRejected = expectation(description: "bad frame rejected by tracking state filter")
        badFrameRejected.expectedFulfillmentCount = 5
        let normalFrameRejected = expectation(description: "normal frame rejected by tracking state filter")
        normalFrameRejected.isInverted = true  // normal frame should _not_ be rejected
        
        let (frameEvaluatorChain, delegate) = TestUtils.makeFrameEvaluatorChainAndDelegate()
        XCTAssertEqual(frameEvaluatorChain.filters.count, 3)
        delegate.didRejectFrameWithFilter = { rejectedFrame, filter, reason in
            guard type(of: filter) == FMTrackingStateFilter.self else {
                return
            }
            if rejectedFrame === normalFrame {
                normalFrameRejected.fulfill()
            } else {
                badFrameRejected.fulfill()
            }
        }
        
        frameEvaluatorChain.evaluateAsync(frame: notAvailableFrame)
        frameEvaluatorChain.evaluateAsync(frame: limitedFrame1)
        frameEvaluatorChain.evaluateAsync(frame: limitedFrame2)
        frameEvaluatorChain.evaluateAsync(frame: limitedFrame3)
        frameEvaluatorChain.evaluateAsync(frame: limitedFrame4)
        frameEvaluatorChain.evaluateAsync(frame: normalFrame)
        
        wait(for: [badFrameRejected, normalFrameRejected], timeout: 0.0)
    }
    
    func testFramePassesAllFilters() throws {
        let mockSession = MockARSession(videoName: "parking-daytime")
        let frame = try mockSession.getNextFrame()
        
        let frameRejected = expectation(description: "frame rejected by filter")
        frameRejected.isInverted = true // frame should _not_ be rejected
        
        let (frameEvaluatorChain, delegate) = TestUtils.makeFrameEvaluatorChainAndDelegate()
        XCTAssertEqual(frameEvaluatorChain.filters.count, 3)
        delegate.didRejectFrameWithFilter = { rejectedFrame, filter, reason in
            if frame === rejectedFrame {
                frameRejected.fulfill()
            }
        }
        
        frameEvaluatorChain.evaluateAsync(frame: frame)
        
        wait(for: [frameRejected], timeout: 0.0)
    }
    
    // MARK: - Image Enhancer
    
    func testImageEnhancerDisabled() throws {
        // create a frame evaluator chain with the image enhancer disabled
        let config = try XCTUnwrap(TestUtils.getTestConfig("image-enhancer-disabled"))
        let (frameEvaluatorChain, delegate) = TestUtils.makeFrameEvaluatorChainAndDelegate(config: config)
        XCTAssertNil(frameEvaluatorChain.imageEnhancer)
        
        // mock session with dark frames that normally would be enhanced
        let mockSession = MockARSession(videoName: "parking-nighttime")
        let darkFrame = try mockSession.getNextFrame()
        
        // expect that the dark frame is evaluated but not enhanced
        let frameEvaluated = expectation(description: "frame evaluated")
        let frameNotEnhanced = expectation(description: "frame not enhanced")
        
        delegate.didFinishEvaluatingFrame = { frame in
            if frame.evaluation != nil, frame === darkFrame {
                frameEvaluated.fulfill()
            }
            if frame.enhancedImage == nil, frame === darkFrame {
                frameNotEnhanced.fulfill()
            }
        }
        
        // evaluate the dark frame and wait
        frameEvaluatorChain.evaluateAsync(frame: darkFrame)
        wait(for: [frameEvaluated, frameNotEnhanced], timeout: 1.0)
    }
    
    func testImageEnhancerEnhancesFrame() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "metal not supported")
        
        // create a frame evaluator chain with the default config
        let config = try XCTUnwrap(TestUtils.getDefaultConfig())
        let (frameEvaluatorChain, delegate) = TestUtils.makeFrameEvaluatorChainAndDelegate(config: config)
        
        // check the image enhancer is enabled and configured correctly
        XCTAssertNotNil(frameEvaluatorChain.imageEnhancer)
        XCTAssertEqual(frameEvaluatorChain.imageEnhancer!.targetBrightness, config.imageEnhancerTargetBrightness)
        
        // mock session with dark frames that should be enhanced
        let mockSession = MockARSession(videoName: "parking-nighttime")
        let darkFrame = try mockSession.getNextFrame()
        
        // expect that the dark frame is evaluated and enhanced
        let frameEvaluated = expectation(description: "frame evaluated")
        let frameEnhanced = expectation(description: "frame enhanced")
        
        delegate.didFinishEvaluatingFrame = { frame in
            if frame.evaluation != nil, frame === darkFrame {
                frameEvaluated.fulfill()
            }
            if frame.enhancedImage != nil, frame === darkFrame {
                frameEnhanced.fulfill()
            }
        }
        
        // evaluate the dark frame and wait
        frameEvaluatorChain.evaluateAsync(frame: darkFrame)
        wait(for: [frameEvaluated, frameEnhanced], timeout: 1.0)
    }
        
    func testFrameEvaluationScoreHigherForEnhancedImage() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "metal not supported")
        
        // create a frame evaluator chain with image enhancement disabled
        let config = try XCTUnwrap(TestUtils.getTestConfig("image-enhancer-disabled"))
        let (nonEnhancingChain, nonEnhancingDelegate) = TestUtils.makeFrameEvaluatorChainAndDelegate(config: config)
        XCTAssertNil(nonEnhancingChain.imageEnhancer)
                        
        // create a dark frame to evaluate twice, first unenhanced then enhanced
        let mockSession = MockARSession(videoName: "parking-nighttime")
        let darkFrame = try mockSession.getNextFrame()
        
        // expect that we will first evaluate an unenhanced frame
        let unenhancedFrameEvaluated = expectation(description: "unenhanced frame evaluated")
        var unenhancedScore: Float = 0
        
        nonEnhancingDelegate.didFinishEvaluatingFrame = { frame in
            if let evaluation = frame.evaluation, frame.enhancedImage == nil, frame === darkFrame {
                // save the unenhanced score
                unenhancedScore = evaluation.score
                unenhancedFrameEvaluated.fulfill()
            }
        }
        
        // wait for unenhanced frame to be evaluated
        nonEnhancingChain.evaluateAsync(frame: darkFrame)
        wait(for: [unenhancedFrameEvaluated], timeout: 1.0)
        
        // enable image enhancement
        let (enhancingChain, enhancingDelegate) = TestUtils.makeFrameEvaluatorChainAndDelegate()
        XCTAssertNotNil(enhancingChain.imageEnhancer)
        
        // expect that we will enhance the same frame
        let enhancedFrameEvaluated = expectation(description: "enhanced frame evaluated")
        var enhancedScore: Float = 0
        
        enhancingDelegate.didFinishEvaluatingFrame = { frame in
            if let evaluation = frame.evaluation, frame.enhancedImage != nil, frame === darkFrame {
                // save the enhanced score
                enhancedScore = evaluation.score
                enhancedFrameEvaluated.fulfill()
            }
        }
        
        // wait for the frame to be enhanced and re-evaluated
        enhancingChain.evaluateAsync(frame: darkFrame)
        wait(for: [enhancedFrameEvaluated], timeout: 1.0)
        
        // check that we have two valid evaluation scores
        XCTAssertTrue(enhancedScore > 0.0 && enhancedScore < 1.0)
        XCTAssertTrue(unenhancedScore > 0.0 && unenhancedScore < 1.0)
        
        // check that the enhanced score is better
        XCTAssertGreaterThan(enhancedScore, unenhancedScore)
    }
}
