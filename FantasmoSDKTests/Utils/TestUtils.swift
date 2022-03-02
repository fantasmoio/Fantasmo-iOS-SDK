//
//  TestUtils.swift
//  FantasmoSDKTests
//
//  Created by Nicholas Jensen on 01.03.22.
//

import Foundation
@testable import FantasmoSDK

class TestUtils {
    
    static func getTestConfig(_ name: String) -> RemoteConfig.Config? {
        let fileUrl = Bundle(for: SDKRemoteConfigTests.self).url(forResource: name, withExtension: "json")!
        return RemoteConfig.Config(from: fileUrl)
    }
    
    static func getDefaultConfig() -> RemoteConfig.Config? {
        let defaultFileUrl = Bundle(for: FMSDKInfo.self).url(forResource: "default-config", withExtension: "json")!
        return RemoteConfig.Config(from: defaultFileUrl)
    }
    
    static func makeFrameEvaluatorChainAndDelegate() -> (FMFrameEvaluatorChain, MockFrameEvaluatorDelegate) {
        let defaultConfig = getDefaultConfig()!
        let frameEvaluatorChain = FMFrameEvaluatorChain(config: defaultConfig)
        let mockDelegate = MockFrameEvaluatorDelegate()
        frameEvaluatorChain.delegate = mockDelegate
        return (frameEvaluatorChain, mockDelegate)
    }
}
