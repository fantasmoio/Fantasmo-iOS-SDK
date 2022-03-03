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
        
        // create a mock session and get a test frame
        let mockSession = MockARSession(videoName: "parking-daytime")
        let frame = try mockSession.getNextFrame()
        
        // perform image quality evaluation
        let evaluation = imageQualityEvaluator.evaluate(frame: frame)
        
        // check that it returned a valid evaluation
        XCTAssertEqual(evaluation.type, .imageQuality)
        XCTAssertGreaterThan(evaluation.score, 0.0)
        XCTAssertLessThan(evaluation.score, 1.0)
        
        // check the evaluation contains userInfo with model version and no error message
        let userInfo = try XCTUnwrap(evaluation.userInfo)
        XCTAssertEqual(userInfo[FMImageQualityEvaluator.versionUserInfoKey], imageQualityEvaluator.modelVersion)
        XCTAssertTrue(userInfo[FMImageQualityEvaluator.errorUserInfoKey] == nil)
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
