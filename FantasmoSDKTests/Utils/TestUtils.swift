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
    
    static func getTestImage(_ name: String) -> UIImage? {
        guard let fileUrl = Bundle(for: SDKRemoteConfigTests.self).url(forResource: name, withExtension: "png") else {
            return nil
        }
        return UIImage(contentsOfFile: fileUrl.path)
    }
    
    static func getTestConfig(_ name: String) -> RemoteConfig.Config? {
        let fileUrl = Bundle(for: SDKRemoteConfigTests.self).url(forResource: name, withExtension: "json")!
        return RemoteConfig.Config(from: fileUrl)
    }
    
    static func getDefaultConfig() -> RemoteConfig.Config? {
        let defaultFileUrl = Bundle(for: FMSDKInfo.self).url(forResource: "default-config", withExtension: "json")!
        return RemoteConfig.Config(from: defaultFileUrl)
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
