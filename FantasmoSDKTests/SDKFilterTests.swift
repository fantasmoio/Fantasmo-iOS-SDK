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

typealias FMFrameFilterResult = FantasmoSDK.FMFrameFilterResult
typealias FMFrame = FantasmoSDK.FMFrame

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
    
    // note: this test will not fail and not throw an error code if the pixelBuffer assignment fails
    func testMovementFilter() {
        let filter = FantasmoSDK.FMMovementFilter(threshold: 0.001)
        var transform = simd_float4x4(1)
        var pixelBuffer: CVPixelBuffer? = nil
        CVPixelBufferCreate(kCFAllocatorDefault, 64, 64, kCVPixelFormatType_OneComponent8, nil, &pixelBuffer)
        if let pixelBuffer = pixelBuffer {
            var frame = FMFrame(camera: MockCamera(transform: transform), capturedImage: pixelBuffer)
            XCTAssertEqual(filter.accepts(frame), .rejected(reason: .movingTooLittle))
            transform = simd_float4x4(1.1)
            frame = FMFrame(camera: MockCamera(transform: transform), capturedImage: pixelBuffer)
            XCTAssertEqual(filter.accepts(frame), .accepted)
            transform = simd_float4x4(1.099)
            XCTAssertEqual(filter.accepts(frame), .rejected(reason: .movingTooLittle))
        } else {
            print ("Couldn't allocate mock pixel buffer")
        }
    }

    // note: this test will not fail and not throw an error code if the nonnilBuffer assignment fails
    func testCameraPitchFilter() {
        let filter = FantasmoSDK.FMCameraPitchFilter(maxUpwardTiltDegrees: 30, maxDownwardTiltDegrees: 65)
        var pixelBuffer: CVPixelBuffer? = nil
        CVPixelBufferCreate(kCFAllocatorDefault, 64, 64, kCVPixelFormatType_OneComponent8, nil, &pixelBuffer)
        var pitch : Float = deg2rad(-90)
        if let nonnilBuffer = pixelBuffer {
            var frame = FMFrame(camera: MockCamera(pitch: pitch), capturedImage: nonnilBuffer)
            XCTAssertEqual(filter.accepts(frame), .rejected(reason: .pitchTooLow))
            pitch = deg2rad(-65)
            frame = FMFrame(camera: MockCamera(pitch: pitch), capturedImage: nonnilBuffer)
            XCTAssertEqual(filter.accepts(frame), .accepted)
            pitch = deg2rad(0)
            frame = FMFrame(camera: MockCamera(pitch: pitch), capturedImage: nonnilBuffer)
            XCTAssertEqual(filter.accepts(frame), .accepted)
            pitch = deg2rad(30)
            frame = FMFrame(camera: MockCamera(pitch: pitch), capturedImage: nonnilBuffer)
            XCTAssertEqual(filter.accepts(frame), .accepted)
            pitch = deg2rad(60)
            frame = FMFrame(camera: MockCamera(pitch: pitch), capturedImage: nonnilBuffer)
            XCTAssertEqual(filter.accepts(frame), .rejected(reason: .pitchTooHigh))
       } else {
            print ("Couldn't allocate mock pixel buffer")
        }
    }
    
    func testBlurFilter() {
        let filter = FantasmoSDK.FMBlurFilter(varianceThreshold: 250, suddenDropThreshold: 0.4, averageThroughputThreshold: 0.25)
        let dayScan = UIImage(named: "dayScan", in: Bundle(for: type(of: self)), compatibleWith: nil)
        let dayScanFrame = FMFrame(camera: MockCamera(), capturedImage: dayScan!.pixelBuffer()!)
        let nightScan = UIImage(named: "nightScan", in: Bundle(for: type(of: self)), compatibleWith: nil)
        let nightScanFrame = FMFrame(camera: MockCamera(), capturedImage: nightScan!.pixelBuffer()!)

        // nighttime passes twice because of no throughput
        XCTAssertEqual(filter.accepts(nightScanFrame), .accepted)
        XCTAssertEqual(filter.accepts(nightScanFrame), .accepted)
        // daytime passes because it has enough variance
        XCTAssertEqual(filter.accepts(dayScanFrame), .accepted)
        XCTAssertEqual(filter.accepts(dayScanFrame), .accepted)
        XCTAssertEqual(filter.accepts(dayScanFrame), .accepted)
        XCTAssertEqual(filter.accepts(dayScanFrame), .accepted)
        // nighttime is rejected 6 times because it is too blurry and the throughput is superior to 0.25 on the last 8 frames
        XCTAssertEqual(filter.accepts(nightScanFrame), .rejected(reason: .imageTooBlurry))
        XCTAssertEqual(filter.accepts(nightScanFrame), .rejected(reason: .imageTooBlurry))
        XCTAssertEqual(filter.accepts(nightScanFrame), .rejected(reason: .imageTooBlurry))
        XCTAssertEqual(filter.accepts(nightScanFrame), .rejected(reason: .imageTooBlurry))
        XCTAssertEqual(filter.accepts(nightScanFrame), .rejected(reason: .imageTooBlurry))
        XCTAssertEqual(filter.accepts(nightScanFrame), .rejected(reason: .imageTooBlurry))
        // on the 7th nighttime picture in a row, throughput gets back under 0.25 and it passes again
        XCTAssertEqual(filter.accepts(nightScanFrame), .accepted)
        XCTAssertEqual(filter.accepts(nightScanFrame), .accepted)
        XCTAssertEqual(filter.accepts(nightScanFrame), .accepted)
        XCTAssertEqual(filter.accepts(nightScanFrame), .accepted)
    }
    
    func testImageQualityFilterResizesPixelBuffer() {
        let inParkingImage = UIImage(named: "inParking", in: Bundle(for: type(of: self)), compatibleWith: nil)
        let testPixelBuffer = inParkingImage!.pixelBuffer()!
        let imageQualityFilter = FantasmoSDK.FMImageQualityFilter(scoreThreshold: 0)
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
    
    func testImageQualityFilterScoreAboveThreshold() {
        let inParkingImage = UIImage(named: "inParking", in: Bundle(for: type(of: self)), compatibleWith: nil)
        let pixelBuffer = inParkingImage!.pixelBuffer()!
        let mockFrame = FMFrame(camera: MockCamera(), capturedImage: pixelBuffer)
        let imageQualityFilter = FantasmoSDK.FMImageQualityFilter(scoreThreshold: 0.0)
        let filterResult = imageQualityFilter.accepts(mockFrame)
        XCTAssertEqual(filterResult, .accepted)
        // Check that a image quality score was given
        XCTAssertGreaterThan(imageQualityFilter.lastImageQualityScore, 0.0)
        XCTAssertLessThanOrEqual(imageQualityFilter.lastImageQualityScore, 1.0)
    }

    func testImageQualityFilterScoreBelowThreshold() {
        let inParkingImage = UIImage(named: "inParking", in: Bundle(for: type(of: self)), compatibleWith: nil)
        let pixelBuffer = inParkingImage!.pixelBuffer()!
        let mockFrame = FMFrame(camera: MockCamera(), capturedImage: pixelBuffer)
        let imageQualityFilter = FantasmoSDK.FMImageQualityFilter(scoreThreshold: 1.0)
        let filterResult = imageQualityFilter.accepts(mockFrame)
        XCTAssertEqual(filterResult, .rejected(reason: .imageQualityScoreBelowThreshold))
        // Check that a image quality score was given
        XCTAssertGreaterThan(imageQualityFilter.lastImageQualityScore, 0.0)
        XCTAssertLessThanOrEqual(imageQualityFilter.lastImageQualityScore, 1.0)
    }
}
