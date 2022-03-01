//
//  SDKFilterTests.swift
//  FantasmoSDKTests
//
//  Created by lucas kuzma on 8/4/21.
//  Modified by che fisher on 27/9/21

import XCTest
import CoreLocation
import ARKit
@testable import FantasmoSDK


class SDKFilterTests: XCTestCase {
    
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
    
    /*
    func testMovementFilter() {
        let filter = FMMovementFilter(threshold: 0.001)
        var transform = simd_float4x4(1)
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, 64, 64, kCVPixelFormatType_OneComponent8, nil, &pixelBuffer)
        var frame = FMFrame(camera: MockCamera(transform: transform), capturedImage: pixelBuffer!)
        XCTAssertEqual(filter.accepts(frame), .rejected(reason: .movingTooLittle))
        transform = simd_float4x4(1.1)
        frame = FMFrame(camera: MockCamera(transform: transform), capturedImage: pixelBuffer!)
        XCTAssertEqual(filter.accepts(frame), .accepted)
        transform = simd_float4x4(1.099)
        XCTAssertEqual(filter.accepts(frame), .rejected(reason: .movingTooLittle))
    }
    
    func testCameraPitchFilter() {
        let filter = FMCameraPitchFilter(maxUpwardTiltDegrees: 30, maxDownwardTiltDegrees: 65)
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, 64, 64, kCVPixelFormatType_OneComponent8, nil, &pixelBuffer)
        var pitch : Float = deg2rad(-90)
        var frame = FMFrame(camera: MockCamera(pitch: pitch), capturedImage: pixelBuffer!)
        XCTAssertEqual(filter.accepts(frame), .rejected(reason: .pitchTooLow))
        pitch = deg2rad(-65)
        frame = FMFrame(camera: MockCamera(pitch: pitch), capturedImage: pixelBuffer!)
        XCTAssertEqual(filter.accepts(frame), .accepted)
        pitch = deg2rad(0)
        frame = FMFrame(camera: MockCamera(pitch: pitch), capturedImage: pixelBuffer!)
        XCTAssertEqual(filter.accepts(frame), .accepted)
        pitch = deg2rad(30)
        frame = FMFrame(camera: MockCamera(pitch: pitch), capturedImage: pixelBuffer!)
        XCTAssertEqual(filter.accepts(frame), .accepted)
        pitch = deg2rad(60)
        frame = FMFrame(camera: MockCamera(pitch: pitch), capturedImage: pixelBuffer!)
        XCTAssertEqual(filter.accepts(frame), .rejected(reason: .pitchTooHigh))
    }
    
    func testBlurFilter() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "metal not supported")
        
        let filter = FMBlurFilter(varianceThreshold: 250, suddenDropThreshold: 0.4, averageThroughputThreshold: 0.25)
        let daytimeSession = MockARSession(videoName: "parking-daytime")
        let nighttimeSession = MockARSession(videoName: "parking-nighttime")

        // check the filter is actually making calculations for the input frames
        let daytimeVariance = filter.calculateVariance(frame: daytimeSession.nextFrame()!)
        XCTAssertNotEqual(daytimeVariance, 0.0)
        let nighttimeVariance = filter.calculateVariance(frame: nighttimeSession.nextFrame()!)
        XCTAssertNotEqual(nighttimeVariance, 0.0)
        
        // nighttime passes twice because of no throughput
        XCTAssertEqual(filter.accepts(nighttimeSession.nextFrame()!), .accepted)
        XCTAssertEqual(filter.accepts(nighttimeSession.nextFrame()!), .accepted)
        
        // daytime passes because it has enough variance
        XCTAssertEqual(filter.accepts(daytimeSession.nextFrame()!), .accepted)
        XCTAssertEqual(filter.accepts(daytimeSession.nextFrame()!), .accepted)
        XCTAssertEqual(filter.accepts(daytimeSession.nextFrame()!), .accepted)
        XCTAssertEqual(filter.accepts(daytimeSession.nextFrame()!), .accepted)
        
        // nighttime is rejected 6 times because it is too blurry and the throughput is superior to 0.25 on the last 6 frames
        XCTAssertEqual(filter.accepts(nighttimeSession.nextFrame()!), .rejected(reason: .imageTooBlurry))
        XCTAssertEqual(filter.accepts(nighttimeSession.nextFrame()!), .rejected(reason: .imageTooBlurry))
        XCTAssertEqual(filter.accepts(nighttimeSession.nextFrame()!), .rejected(reason: .imageTooBlurry))
        XCTAssertEqual(filter.accepts(nighttimeSession.nextFrame()!), .rejected(reason: .imageTooBlurry))
        XCTAssertEqual(filter.accepts(nighttimeSession.nextFrame()!), .rejected(reason: .imageTooBlurry))
        XCTAssertEqual(filter.accepts(nighttimeSession.nextFrame()!), .rejected(reason: .imageTooBlurry))
        
        // on the 7th nighttime picture in a row, throughput gets back under 0.25 and it passes again
        XCTAssertEqual(filter.accepts(nighttimeSession.nextFrame()!), .accepted)
        XCTAssertEqual(filter.accepts(nighttimeSession.nextFrame()!), .accepted)
        XCTAssertEqual(filter.accepts(nighttimeSession.nextFrame()!), .accepted)
        XCTAssertEqual(filter.accepts(nighttimeSession.nextFrame()!), .accepted)
    }
    
    func testImageQualityFilterResizesPixelBuffer() throws {
        let inParkingImage = UIImage(named: "inParking", in: Bundle(for: type(of: self)), compatibleWith: nil)
        let testPixelBuffer = inParkingImage!.pixelBuffer()!
        let imageQualityFilter = FMImageQualityEvaluator(scoreThreshold: 0)
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
    
    func testImageQualityFilterScoreAboveThreshold() throws {
        let inParkingImage = UIImage(named: "inParking", in: Bundle(for: type(of: self)), compatibleWith: nil)
        let pixelBuffer = inParkingImage!.pixelBuffer()!
        let mockFrame = FMFrame(camera: MockCamera(), capturedImage: pixelBuffer)
        let imageQualityFilter = FMImageQualityEvaluator(scoreThreshold: 0.0)
        let filterResult = imageQualityFilter.accepts(mockFrame)
        XCTAssertEqual(filterResult, .accepted)
        // Check that a image quality score was given
        XCTAssertGreaterThan(imageQualityFilter.lastImageQualityScore, 0.0)
        XCTAssertLessThanOrEqual(imageQualityFilter.lastImageQualityScore, 1.0)
    }

    func testImageQualityFilterScoreBelowThreshold() throws {
        let inParkingImage = UIImage(named: "inParking", in: Bundle(for: type(of: self)), compatibleWith: nil)
        let pixelBuffer = inParkingImage!.pixelBuffer()!
        let mockFrame = FMFrame(camera: MockCamera(), capturedImage: pixelBuffer)
        let imageQualityFilter = FMImageQualityEvaluator(scoreThreshold: 1.0)
        let filterResult = imageQualityFilter.accepts(mockFrame)
        XCTAssertEqual(filterResult, .rejected(reason: .imageQualityScoreBelowThreshold))
        // Check that a image quality score was given
        XCTAssertGreaterThan(imageQualityFilter.lastImageQualityScore, 0.0)
        XCTAssertLessThanOrEqual(imageQualityFilter.lastImageQualityScore, 1.0)
    }
    
    func testGammaCorrectionImprovesImageQualityScore() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "metal not supported")
        
        let nighttimeSession = MockARSession(videoName: "parking-nighttime")
        let imageQualityFilter = FMImageQualityEvaluator(scoreThreshold: 1.0)
        
        let nighttimeFrame = nighttimeSession.nextFrame()!
        let _ = imageQualityFilter.accepts(nighttimeFrame)
        let originalScore = imageQualityFilter.lastImageQualityScore

        let imageEnhancer = FMImageEnhancer(targetBrightness: 0.15)
        imageEnhancer!.enhance(frame: nighttimeFrame)
        let _ = imageQualityFilter.accepts(nighttimeFrame)
        let enhancedScore = imageQualityFilter.lastImageQualityScore
        
        // check the score increased
        XCTAssertGreaterThan(enhancedScore, originalScore)
    }
     */
}
