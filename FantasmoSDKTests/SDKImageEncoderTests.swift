//
//  SDKImageEncoderTests.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 09.02.22.
//

import XCTest
@testable import FantasmoSDK

class SDKImageEncoderTests: XCTestCase {
    
    func testImageEncoderReturnsValidEnhancedImage() throws {
        try XCTSkipIf(MTLCreateSystemDefaultDevice() == nil, "metal not supported")
        
        let imageEncoder = ImageEncoder(largestSingleOutputDimension: 1280)
        let mockSession = MockARSession(videoName: "parking-nighttime")
        let mockFrame = try mockSession.getNextFrame()
        
        // enhance the image, applies gamma correction
        let imageEnhancer = try XCTUnwrap(FMImageEnhancer(targetBrightness: 0.15))
        imageEnhancer.enhance(frame: mockFrame)
        
        // make sure we have an enhanced image
        let enhancedPixelBuffer = try XCTUnwrap(mockFrame.enhancedImage)
        
        // resize and encode the enhanced image
        let enhancedEncodedImage = try XCTUnwrap(imageEncoder.encodedImage(pixelBuffer: enhancedPixelBuffer, deviceOrientation: mockFrame.deviceOrientation))
        
        // check we can create an image from the enhanced image data
        let enhancedImage = try XCTUnwrap(UIImage(data: enhancedEncodedImage.data))
        
        // check the enhanced image was resized correctly
        XCTAssertEqual(enhancedImage.size.width, 1280)
        XCTAssertEqual(enhancedImage.size.height, 720)
    }
    
    func testReturnsImageInPortraitOrientation() throws {
        // create a new image encoder
        let imageEncoder = ImageEncoder(largestSingleOutputDimension: 640)
        
        // create a mock camera simulating a user holding the device upright in portrait
        let portraitCamera = MockCamera(pitch: 0, yaw: 0, roll: -Float.pi / 2.0)
        
        // create a mock ARKit session whose frame buffers are rotated 90° to the left
        let mockSession = MockARSession(videoName: "parking-daytime")
        let mockFrame = try mockSession.getNextFrame(portraitCamera)
        
        // resize and encode the frame
        let encodedImage = try XCTUnwrap(imageEncoder.encodedImage(frame: mockFrame))
        
        // check the returned image orientation is "right" which means the image has been
        // rotated 90° clockwise from the orientation of its original pixel data.
        XCTAssertEqual(encodedImage.orientation, .right)
        
        // check we can create an image from the encoded image data
        let image = try XCTUnwrap(UIImage(data: encodedImage.data))
        
        // check the image was resized correctly and is in portrait orientation
        XCTAssertEqual(image.size.height, 640)
        XCTAssertEqual(image.size.width, 360)
    }
    
    func testReturnsImageInLandscapeOrientation() throws {
        // create a new image encoder
        let imageEncoder = ImageEncoder(largestSingleOutputDimension: 640)
        
        // create a mock camera simulating a user holding the device rotated 90° to the left
        let landscapeCamera = MockCamera(pitch: 0, yaw: 0, roll: 0)
        
        // create a mock ARKit session whose frame buffers are rotated 90° to the left
        let mockSession = MockARSession(videoName: "parking-daytime")
        let mockFrame = try mockSession.getNextFrame(landscapeCamera)
        
        // resize and encode the frame
        let encodedImage = try XCTUnwrap(imageEncoder.encodedImage(frame: mockFrame))
        
        // check the returned image orientation is "up" which means the image orientation matches
        // its original pixel data
        XCTAssertEqual(encodedImage.orientation, .up)
        
        // check we can create an image from the encoded image data
        let image = try XCTUnwrap(UIImage(data: encodedImage.data))
        
        // check the image was resized correctly and is in landscape orientation
        XCTAssertEqual(image.size.width, 640)
        XCTAssertEqual(image.size.height, 360)
    }
}
