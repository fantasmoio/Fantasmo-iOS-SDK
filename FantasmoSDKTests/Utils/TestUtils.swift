//
//  TestUtils.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 01.03.22.
//

import Foundation
import UIKit
@testable import FantasmoSDK

class TestUtils {

    static func url(for filename: String) -> URL? {
        guard let lastDotIndex = filename.lastIndex(of: ".") else {
            return nil
        }
        let name = String(filename.prefix(upTo: lastDotIndex))
        let ext = String(filename.suffix(from: filename.index(after: lastDotIndex)))
        return Bundle(for: TestUtils.self).url(forResource: name, withExtension: ext)
    }
    
    static func getTestImage(_ name: String) -> UIImage? {
        guard let fileUrl = Bundle(for: TestUtils.self).url(forResource: name, withExtension: "png") else {
            return nil
        }
        return UIImage(contentsOfFile: fileUrl.path)
    }
    
    static func getTestConfig(_ name: String) -> RemoteConfig.Config? {
        let fileUrl = Bundle(for: TestUtils.self).url(forResource: name, withExtension: "json")!
        return RemoteConfig.Config(from: fileUrl)
    }
    
    static func getDefaultConfig() -> RemoteConfig.Config? {
        let defaultFileUrl = Bundle(for: FMSDKInfo.self).url(forResource: "default-config", withExtension: "json")!
        return RemoteConfig.Config(from: defaultFileUrl)
    }
    
    static func makeTestConfig(remoteConfigId: String = "test-config",
                               isBehaviorRequesterEnabled: Bool = true,
                               isTrackingStateFilterEnabled: Bool = true,
                               isMovementFilterEnabled: Bool = true,
                               movementFilterThreshold: Float = 0.001,
                               isCameraPitchFilterEnabled: Bool = true,
                               cameraPitchFilterMaxUpwardTilt: Float = 30.0,
                               cameraPitchFilterMaxDownwardTilt: Float = 65.0,
                               isImageEnhancerEnabled: Bool = true,
                               imageEnhancerTargetBrightness: Float = 0.15,
                               imageQualityFilterModelUri: String? = nil,
                               imageQualityFilterModelVersion: String? = nil,
                               minLocalizationWindowTime: TimeInterval = 0.4,
                               maxLocalizationWindowTime: TimeInterval = 1.2,
                               minFrameEvaluationScore: Float = 0.2,
                               minFrameEvaluationHighQualityScore: Float = 0.8) -> RemoteConfig.Config {
        return RemoteConfig.Config(remoteConfigId: remoteConfigId,
                                   isBehaviorRequesterEnabled: isBehaviorRequesterEnabled,
                                   isTrackingStateFilterEnabled: isTrackingStateFilterEnabled,
                                   isMovementFilterEnabled: isMovementFilterEnabled,
                                   movementFilterThreshold: movementFilterThreshold,
                                   isCameraPitchFilterEnabled: isCameraPitchFilterEnabled,
                                   cameraPitchFilterMaxUpwardTilt: cameraPitchFilterMaxUpwardTilt,
                                   cameraPitchFilterMaxDownwardTilt: cameraPitchFilterMaxDownwardTilt,
                                   isImageEnhancerEnabled: isImageEnhancerEnabled,
                                   imageEnhancerTargetBrightness: imageEnhancerTargetBrightness,
                                   imageQualityFilterModelUri: imageQualityFilterModelUri,
                                   imageQualityFilterModelVersion: imageQualityFilterModelVersion,
                                   minLocalizationWindowTime: minLocalizationWindowTime,
                                   maxLocalizationWindowTime: maxLocalizationWindowTime,
                                   minFrameEvaluationScore: minFrameEvaluationScore,
                                   minFrameEvaluationHighQualityScore: minFrameEvaluationHighQualityScore)
    }

    static func makeFrameEvaluatorChainAndDelegate(config: RemoteConfig.Config) -> (FMFrameEvaluatorChain, MockFrameEvaluatorDelegate) {
        let frameEvaluatorChain = FMFrameEvaluatorChain(config: config)
        let mockDelegate = MockFrameEvaluatorDelegate()
        frameEvaluatorChain.delegate = mockDelegate
        return (frameEvaluatorChain, mockDelegate)
    }
    
    static func makeFrameEvaluatorChainAndDelegate() -> (FMFrameEvaluatorChain, MockFrameEvaluatorDelegate) {
        return makeFrameEvaluatorChainAndDelegate(config: getDefaultConfig()!)
    }
}
