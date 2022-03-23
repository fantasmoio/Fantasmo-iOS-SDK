//
//  SDKFrameFilterTests.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 01.03.22.
//

import simd
import XCTest
@testable import FantasmoSDK


class SDKFrameFilterTests: XCTestCase {
    
    func testMovementFilter() throws {
        let filter = FMMovementFilter(threshold: 0.001)
        var transform = simd_float4x4(1)
        var pixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, 64, 64, kCVPixelFormatType_OneComponent8, nil, &pixelBuffer)
        var frame = FMFrame(camera: MockCamera(transform: transform), capturedImage: pixelBuffer!)
        XCTAssertEqual(filter.accepts(frame), .rejected(reason: .movingTooLittle))
        transform = simd_float4x4(1.1)
        frame = FMFrame(camera: MockCamera(transform: transform), capturedImage: pixelBuffer!)
        XCTAssertEqual(filter.accepts(frame), .accepted)
        XCTAssertEqual(filter.accepts(frame), .rejected(reason: .movingTooLittle))
    }

    func testCameraPitchFilter() throws {
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
    
    func testTrackingStateFilter() throws {
        let filter = FMTrackingStateFilter()
        let mockSession = MockARSession(videoName: "parking-daytime")
        
        let notAvailableFrame = try mockSession.getNextFrame(MockCamera(trackingState: .notAvailable))
        XCTAssertEqual(filter.accepts(notAvailableFrame), .rejected(reason: .trackingStateNotAvailable))

        let initializingFrame = try mockSession.getNextFrame(MockCamera(trackingState: .limited(.initializing)))
        XCTAssertEqual(filter.accepts(initializingFrame), .rejected(reason: .trackingStateInitializing))

        let relocalizingFrame = try mockSession.getNextFrame(MockCamera(trackingState: .limited(.relocalizing)))
        XCTAssertEqual(filter.accepts(relocalizingFrame), .rejected(reason: .trackingStateRelocalizing))
        
        let excessiveMotionFrame = try mockSession.getNextFrame(MockCamera(trackingState: .limited(.excessiveMotion)))
        XCTAssertEqual(filter.accepts(excessiveMotionFrame), .rejected(reason: .trackingStateExcessiveMotion))

        let insufficientFeaturesFrame = try mockSession.getNextFrame(MockCamera(trackingState: .limited(.insufficientFeatures)))
        XCTAssertEqual(filter.accepts(insufficientFeaturesFrame), .rejected(reason: .trackingStateInsufficentFeatures))

        let normalFrame = try mockSession.getNextFrame(MockCamera(trackingState: .normal))
        XCTAssertEqual(filter.accepts(normalFrame), .accepted)
    }
}
