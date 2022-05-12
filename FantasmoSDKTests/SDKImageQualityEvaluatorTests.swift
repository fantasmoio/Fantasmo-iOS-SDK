//
//  SDKImageQualityEvaluatorTests.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 01.03.22.
//

import XCTest
import CoreML
@testable import FantasmoSDK


class SDKImageQualityEvaluatorTests: XCTestCase {
    
    let rgbMean: (Float, Float, Float) = (0.485, 0.456, 0.406)
    let rgbStdDev: (Float, Float, Float) = (0.229, 0.224, 0.225)
    
    override class func setUp() {
        // Tests are based on the latest bundled model
        ImageQualityModel.removeDownloadedModel()
    }
    
    func testCreatesMLInput() throws {
        // create a new evaluator
        let imageQualityEvaluator = try XCTUnwrap(FMImageQualityEvaluator.makeEvaluator() as? FMImageQualityEvaluatorCoreML)
        
        // specify that we're working with portrait oriented frames
        imageQualityEvaluator.sourcePixelBuffersAreRotated = false
        
        // create a test portrait frame
        let portraitImage = TestUtils.getTestImage("iqe-test-frame")
        let portraitPixelBuffer = try XCTUnwrap(portraitImage?.pixelBuffer())
        
        // resize the test frame
        let resizedPixelBuffer = try XCTUnwrap(imageQualityEvaluator.makeResizedPixelBuffer(portraitPixelBuffer))
        
        // create and populate an ml input array from resized pixel buffer
        let mlInputArray = try XCTUnwrap(imageQualityEvaluator.makeInputArray())
        imageQualityEvaluator.populateInputArray(mlInputArray, from: resizedPixelBuffer)
        
        // check the first input element is a single red pixel
        XCTAssertEqual(mlInputArray[[0, 0, 0, 0]] as? Float, (1.0 - rgbMean.0) / rgbStdDev.0)
        XCTAssertEqual(mlInputArray[[0, 1, 0, 0]] as? Float, (0.0 - rgbMean.1) / rgbStdDev.1)
        XCTAssertEqual(mlInputArray[[0, 2, 0, 0]] as? Float, (0.0 - rgbMean.2) / rgbStdDev.2)
        
        // check the last input element is a single green pixel
        XCTAssertEqual(mlInputArray[[0, 0, 319, 239]] as? Float, (0.0 - rgbMean.0) / rgbStdDev.0)
        XCTAssertEqual(mlInputArray[[0, 1, 319, 239]] as? Float, (1.0 - rgbMean.1) / rgbStdDev.1)
        XCTAssertEqual(mlInputArray[[0, 2, 319, 239]] as? Float, (0.0 - rgbMean.2) / rgbStdDev.2)
    }
        
    func testCreatesMLInputFromRotatedFrame() throws {
        // create a new evaluator
        let imageQualityEvaluator = try XCTUnwrap(FMImageQualityEvaluator.makeEvaluator() as? FMImageQualityEvaluatorCoreML)
        
        // specify that we're working with frames rotated 90° to the left, this simulates ARKit frames
        imageQualityEvaluator.sourcePixelBuffersAreRotated = true
        
        // create a test frame rotated 90° to the left
        let rotatedImage = TestUtils.getTestImage("iqe-test-frame-rotated")
        let rotatedPixelBuffer = try XCTUnwrap(rotatedImage?.pixelBuffer())
        
        // resize the test frame
        let resizedPixelBuffer = try XCTUnwrap(imageQualityEvaluator.makeResizedPixelBuffer(rotatedPixelBuffer))
        
        // create and populate an ml input array from resized pixel buffer
        let mlInputArray = try XCTUnwrap(imageQualityEvaluator.makeInputArray())
        imageQualityEvaluator.populateInputArray(mlInputArray, from: resizedPixelBuffer)
        
        // check the first input element is a single red pixel
        XCTAssertEqual(mlInputArray[[0, 0, 0, 0]] as? Float, (1.0 - rgbMean.0) / rgbStdDev.0)
        XCTAssertEqual(mlInputArray[[0, 1, 0, 0]] as? Float, (0.0 - rgbMean.1) / rgbStdDev.1)
        XCTAssertEqual(mlInputArray[[0, 2, 0, 0]] as? Float, (0.0 - rgbMean.2) / rgbStdDev.2)
        
        // check the last input element is a single green pixel
        XCTAssertEqual(mlInputArray[[0, 0, 319, 239]] as? Float, (0.0 - rgbMean.0) / rgbStdDev.0)
        XCTAssertEqual(mlInputArray[[0, 1, 319, 239]] as? Float, (1.0 - rgbMean.1) / rgbStdDev.1)
        XCTAssertEqual(mlInputArray[[0, 2, 319, 239]] as? Float, (0.0 - rgbMean.2) / rgbStdDev.2)
    }
    
    func testResizeSettings() throws {
        // create a new evaluator
        let imageQualityEvaluator = try XCTUnwrap(FMImageQualityEvaluator.makeEvaluator() as? FMImageQualityEvaluatorCoreML)

        // check default resize settings
        XCTAssertTrue(imageQualityEvaluator.sourcePixelBuffersAreRotated)
        XCTAssertEqual(imageQualityEvaluator.resizedPixelBufferWidth, 320)
        XCTAssertEqual(imageQualityEvaluator.resizedPixelBufferHeight, 240)
        
        // check resize dimensions are flipped when working with portrait frames
        imageQualityEvaluator.sourcePixelBuffersAreRotated = false
        XCTAssertEqual(imageQualityEvaluator.resizedPixelBufferWidth, 240)
        XCTAssertEqual(imageQualityEvaluator.resizedPixelBufferHeight, 320)
    }
    
    func testExpectedImageQualityScores() throws {
        // create a new evaluator
        let imageQualityEvaluator = try XCTUnwrap(FMImageQualityEvaluator.makeEvaluator() as? FMImageQualityEvaluatorCoreML)

        // create a mock daytime AR session and get a test frame
        let daytimeSession = MockARSession(videoName: "parking-daytime")
        let daytimeFrame = try daytimeSession.getNextFrame()
        
        // check the evaluation score is what we expect
        let daytimeEvaluation = imageQualityEvaluator.evaluate(frame: daytimeFrame)
        XCTAssertEqual(daytimeEvaluation.score, 0.76551, accuracy: 0.01)
        
        // create a mock nighttime AR session and get a test frame
        let nighttimeSession = MockARSession(videoName: "parking-nighttime")
        let nighttimeFrame = try nighttimeSession.getNextFrame()
        
        // check the evaluation score is what we expect
        let nighttimeEvaluation = imageQualityEvaluator.evaluate(frame: nighttimeFrame)
        XCTAssertEqual(nighttimeEvaluation.score, 0.81611, accuracy: 0.01)
    }
    
    func testReturnsImageQualityUserInfo() throws {
        // create a new evaluator
        let imageQualityEvaluator = try XCTUnwrap(FMImageQualityEvaluator.makeEvaluator() as? FMImageQualityEvaluatorCoreML)

        // create a AR session and evaluate a test frame
        let session = MockARSession(videoName: "parking-daytime")
        let frame = try session.getNextFrame()
        let evaluation = imageQualityEvaluator.evaluate(frame: frame)
        
        // check image quality user info was returned
        let userInfo = try XCTUnwrap(evaluation.imageQualityUserInfo)
        XCTAssertEqual(userInfo.modelVersion, imageQualityEvaluator.modelVersion)
        XCTAssertNil(userInfo.error)
    }
}
