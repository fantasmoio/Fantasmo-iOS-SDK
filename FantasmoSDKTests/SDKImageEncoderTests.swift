//
//  SDKImageEncoderTests.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 09.02.22.
//

import XCTest
@testable import FantasmoSDK

class SDKImageEncoderTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testImageEncoderReturnsValidImage() throws {
        let imageEncoder = FantasmoSDK.ImageEncoder(largestSingleOutputDimension: 1280)
        let mockSession = MockARSession(videoName: "parking-daytime")
        let mockFrame = mockSession.nextFrame()!
        let encodedImage = imageEncoder.encodedImage(from: mockFrame)
        XCTAssertNotNil(encodedImage)
        XCTAssertNotNil(UIImage(data: encodedImage!.data))
    }

    func testImageEncoderResizes() throws {
        let imageEncoder = FantasmoSDK.ImageEncoder(largestSingleOutputDimension: 640)
        let mockSession = MockARSession(videoName: "parking-daytime")
        let mockFrame = mockSession.nextFrame()!
        let encodedImage = imageEncoder.encodedImage(from: mockFrame)
        
        // check frame was resized to the correct dimension
        let uiImage = UIImage(data: encodedImage!.data)
        XCTAssertEqual(uiImage!.size.height, 640)
        XCTAssertEqual(uiImage!.size.height, encodedImage!.resolution.height)
    
        // check the aspect ratio was maintained
        let originalWidth = CGFloat(CVPixelBufferGetWidth(mockFrame.capturedImage))
        let originalHeight = CGFloat(CVPixelBufferGetHeight(mockFrame.capturedImage))
        XCTAssertEqual(uiImage!.size.width, (640.0 * originalWidth / originalHeight))
    }    
}