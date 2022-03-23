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
        // check factory constructor produces the CoreML evaluator
        let imageQualityEvaluator = try XCTUnwrap(FMImageQualityEvaluator.makeEvaluator() as? FMImageQualityEvaluatorCoreML)
        
        // create a mock daytime session and get a test frame
        let daytimeSession = MockARSession(videoName: "parking-daytime")
        let daytimeFrame = try daytimeSession.getNextFrame()
        
        // perform image quality evaluation on a daytime frame
        let daytimeEvaluation = imageQualityEvaluator.evaluate(frame: daytimeFrame)
        
        // check that it returned a valid evaluation
        XCTAssertEqual(daytimeEvaluation.type, .imageQuality)
        XCTAssertGreaterThan(daytimeEvaluation.score, 0.0)
        XCTAssertLessThan(daytimeEvaluation.score, 1.0)

        // check the evaluation contains userInfo with model version and no error message
        let userInfo = try XCTUnwrap(daytimeEvaluation.userInfo)
        XCTAssertEqual(userInfo[imageQualityEvaluator.modelVersionUserInfoKey], imageQualityEvaluator.modelVersion)
        XCTAssertTrue(userInfo[imageQualityEvaluator.errorUserInfoKey] == nil)
        
        // check evaluating the same frame again produces the same score
        let duplicateEvaluation = imageQualityEvaluator.evaluate(frame: daytimeFrame)
        XCTAssertEqual(duplicateEvaluation.score, daytimeEvaluation.score)
        
        // create a mock nighttime session and get a test frame
        let nighttimeSession = MockARSession(videoName: "parking-nighttime")
        let nighttimeFrame = try nighttimeSession.getNextFrame()
        
        // perform image quality evaluation on a daytime frame
        let nighttimeEvaluation = imageQualityEvaluator.evaluate(frame: nighttimeFrame)
        
        // check that it returned a valid evaluation
        XCTAssertEqual(nighttimeEvaluation.type, .imageQuality)
        XCTAssertGreaterThan(nighttimeEvaluation.score, 0.0)
        XCTAssertLessThan(nighttimeEvaluation.score, 1.0)
        
        // check that the two scores are different
        XCTAssertNotEqual(daytimeEvaluation.score, nighttimeEvaluation.score)
    }
    
    func testImageQualityEvaluatorResizesPixelBuffer() throws {
        // check factory constructor produces the CoreML evaluator
        let imageQualityEvaluator = try XCTUnwrap(FMImageQualityEvaluator.makeEvaluator() as? FMImageQualityEvaluatorCoreML)
        
        // create a mock session and get a test frame
        let mockSession = MockARSession(videoName: "parking-daytime")
        let frame = try mockSession.getNextFrame()
        
        let resizedPixelBufferContext = imageQualityEvaluator.makeResizedPixelBuffer(frame.capturedImage)
        
        // Check the returned context has a buffer pointer
        XCTAssertNotNil(resizedPixelBufferContext?.data)
        
        let cgImage = resizedPixelBufferContext?.makeImage()
        XCTAssertNotNil(cgImage)
        
        // Check we can create an image from the buffer and that it's the correct size
        let resizedImage = UIImage(cgImage: try XCTUnwrap(cgImage))
        XCTAssertEqual(resizedImage.size.width, 320)
        XCTAssertEqual(resizedImage.size.height, 240)
    }
}
