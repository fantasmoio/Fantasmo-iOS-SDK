//
//  SDKFrameEvaluatorTests.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 01.03.22.
//

import XCTest
import CoreLocation
import ARKit
@testable import FantasmoSDK


class SDKFrameEvaluatorTests: XCTestCase {
    
    func getDefaultFrameEvaluatorChain() -> FMFrameEvaluatorChain {
        let defaultConfigUrl = Bundle(for: FMSDKInfo.self).url(forResource: "default-config", withExtension: "json")!
        let defaultConfig = RemoteConfig.Config(from: defaultConfigUrl)!
        return FMFrameEvaluatorChain(config: defaultConfig)
    }
            
    func testFrameRejectedByMovementFilter() {
        let frameEvaluatorChain = getDefaultFrameEvaluatorChain()
        let movementFilter = frameEvaluatorChain.getFilter(ofType: FMMovementFilter.self)
        XCTAssertEqual(movementFilter!.threshold, 0.001)
                
        let mockSession = MockARSession(videoName: "parking-daytime")
        let firstFrame = mockSession.nextFrame(camera: MockCamera(transform: simd_float4x4(1), trackingState: .normal))!
        let secondFrame = mockSession.nextFrame(camera: MockCamera(transform: simd_float4x4(1.1), trackingState: .normal))!
        
        let firstFrameRejected = expectation(description: "first frame rejected by movement filter")
        let secondFrameRejected = expectation(description: "second frame rejected by movement filter")
        secondFrameRejected.isInverted = true  // second frame should _not_ be rejected
        
        let mockDelegate = MockFrameEvaluatorDelegate()
        frameEvaluatorChain.delegate = mockDelegate
        mockDelegate.didRejectFrameWithFilter = { rejectedFrame, filter, reason in
            guard type(of: filter) == FMMovementFilter.self else {
                return
            }
            if firstFrame === rejectedFrame, reason == .movingTooLittle {
                firstFrameRejected.fulfill()
            } else if secondFrame === rejectedFrame {
                secondFrameRejected.fulfill()
            }
        }
        
        frameEvaluatorChain.evaluateAsync(frame: firstFrame)
        frameEvaluatorChain.evaluateAsync(frame: secondFrame)
        
        wait(for: [firstFrameRejected, secondFrameRejected], timeout: 0.0)
    }
}
