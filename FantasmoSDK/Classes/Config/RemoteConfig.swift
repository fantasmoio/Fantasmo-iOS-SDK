//
//  RemoteConfig.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 22.11.21.
//

import Foundation

class RemoteConfig {
            
    struct Config: Codable {
        let frameAcceptanceThresholdTimeout: Float
        let isBehaviorRequesterEnabled: Bool
        let isTrackingStateFilterEnabled: Bool
        let isMovementFilterEnabled: Bool
        let movementFilterThreshold: Float
        let isBlurFilterEnabled: Bool
        let blurFilterVarianceThreshold: Float
        let blurFilterSuddenDropThreshold: Float
        let blurFilterAverageThroughputThreshold: Float
        let isCameraPitchFilterEnabled: Bool
        let cameraPitchFilterMaxUpwardTilt: Float
        let cameraPitchFilterMaxDownwardTilt: Float
    }
        
    private static let userDefaultsKey = "FantasmoSDK.RemoteConfig"
    
    private static var _config: RemoteConfig.Config!
    
    static func config() -> RemoteConfig.Config {
        guard _config == nil else {
            return _config
        }
        
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // check if we have a previously downloaded config object
        if let savedConfigData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedConfig = try? jsonDecoder.decode(Config.self, from: savedConfigData) {
            log.info("successfully loaded saved remote config")
            _config = savedConfig
            return _config
        }
        
        // load the default config file from the SDK bundle
        guard let defaultConfigUrl = Bundle(for: RemoteConfig.self).url(forResource: "default-config", withExtension: "json"),
              let defaultConfigData = try? Data(contentsOf: defaultConfigUrl),
              let defaultConfig = try? jsonDecoder.decode(Config.self, from: defaultConfigData)
        else {
            fatalError("failed to parse SDK default config")
        }
        
        _config = defaultConfig
        return defaultConfig
    }
}
