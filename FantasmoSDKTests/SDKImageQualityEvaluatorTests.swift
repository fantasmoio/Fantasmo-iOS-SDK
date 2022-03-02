//
//  SDKImageQualityEvaluatorTests.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 01.03.22.
//

import XCTest
@testable import FantasmoSDK


class SDKImageQualityEvaluatorTests: XCTestCase {

    func testImageQualityEvaluator() throws {
        let mockSession = MockARSession(videoName: "parking-daytime")
        let mockFrame = try mockSession.getNextFrame()
        
        var frameEvaluation: FMFrameEvaluation?
        let frameEvaluated = expectation(description: "frame evaluated")
        
        let (frameEvaluatorChain, delegate) = TestUtils.makeFrameEvaluatorChainAndDelegate()
        delegate.didFinishEvaluatingFrame = { frame in
            guard let evaluation = frame.evaluation else {
                return
            }
            frameEvaluation = evaluation
            frameEvaluated.fulfill()
        }
        
        frameEvaluatorChain.evaluateAsync(frame: mockFrame)
        wait(for: [frameEvaluated], timeout: 3.0)
        
        // check that we got a valid frame evaluation
        XCTAssertNotNil(frameEvaluation)
        XCTAssertEqual(frameEvaluation!.type, .imageQuality)
        XCTAssertGreaterThan(frameEvaluation!.score, 0.0)
        XCTAssertLessThan(frameEvaluation!.score, 1.0)
    }
    
    /// TODO
    /// - implement this
    
    func testImageQualityHigherWhenEnhanced() throws {
        let daytimeSession = MockARSession(videoName: "parking-daytime")
        let daytimeFrame = try daytimeSession.getNextFrame()
        var daytimeEvaluation: FMFrameEvaluation?
        let daytimeFrameEvaluated = expectation(description: "daytime frame evaluated")
        let (frameEvaluatorChain, delegate) = TestUtils.makeFrameEvaluatorChainAndDelegate()
        delegate.didFinishEvaluatingFrame = { frame in
            guard let evaluation = frame.evaluation else {
                return
            }
            daytimeEvaluation = evaluation
            daytimeFrameEvaluated.fulfill()
        }
        
        frameEvaluatorChain.evaluateAsync(frame: daytimeFrame)
        wait(for: [daytimeFrameEvaluated], timeout: 3.0)
        
        // check that we got a valid daytime frame evaluation
        XCTAssertNotNil(daytimeEvaluation)
        XCTAssertEqual(daytimeEvaluation!.type, .imageQuality)
        XCTAssertGreaterThan(daytimeEvaluation!.score, 0.0)
        XCTAssertLessThan(daytimeEvaluation!.score, 1.0)

        let nighttimeSession = MockARSession(videoName: "parking-nighttime")
        let nighttimeFrame = try nighttimeSession.getNextFrame()
        var nighttimeEvaluation: FMFrameEvaluation?
        let nighttimeFrameEvaluated = expectation(description: "nighttime frame evaluated")
        delegate.didFinishEvaluatingFrame = { frame in
            guard let evaluation = frame.evaluation else {
                return
            }
            nighttimeEvaluation = evaluation
            nighttimeFrameEvaluated.fulfill()
        }
                
        frameEvaluatorChain.evaluateAsync(frame: nighttimeFrame)
        wait(for: [nighttimeFrameEvaluated], timeout: 3.0)
        
        // check that we got a valid nighttime frame evaluation
        XCTAssertNotNil(nighttimeEvaluation)
        XCTAssertEqual(nighttimeEvaluation!.type, .imageQuality)
        XCTAssertGreaterThan(nighttimeEvaluation!.score, 0.0)
        XCTAssertLessThan(nighttimeEvaluation!.score, 1.0)
        
        // check that the daytime score is better than the nighttime score
        //XCTAssertGreaterThan(daytimeEvaluation!.score, nighttimeEvaluation!.score)
    }
}

/*
 func testImageQualityFilterResizesPixelBuffer() throws {
     let inParkingImage = UIImage(named: "inParking", in: Bundle(for: type(of: self)), compatibleWith: nil)
     let testPixelBuffer = inParkingImage!.pixelBuffer()!
     let imageQualityFilter = FMImageQualityFilter(scoreThreshold: 0)
     let resizedPixelBufferContext = imageQualityFilter.makeResizedPixelBuffer(testPixelBuffer)
     // Check the returned context has a buffer pointer
     XCTAssertNotNil(resizedPixelBufferContext?.data)
     let cgImage = resizedPixelBufferContext!.makeImage()
     XCTAssertNotNil(cgImage)
     // Check we can create an image from the buffer and that it's the correct size
     let resizedImage = UIImage(cgImage: cgImage!)
     XCTAssertEqual(resizedImage.size.width, 320)
     XCTAssertEqual(resizedImage.size.height, 240)
 }

 */
