//
//  RemoteConfig.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 22.11.21.
//

import Foundation

class RemoteConfig {
            
    struct Config: Codable {
        let remoteConfigId: String
        let isBehaviorRequesterEnabled: Bool
        let isTrackingStateFilterEnabled: Bool
        let isMovementFilterEnabled: Bool
        let movementFilterThreshold: Float
        let isCameraPitchFilterEnabled: Bool
        let cameraPitchFilterMaxUpwardTilt: Float
        let cameraPitchFilterMaxDownwardTilt: Float
        let isImageEnhancerEnabled: Bool
        let imageEnhancerTargetBrightness: Float
        let imageQualityFilterModelUri: String?
        let imageQualityFilterModelVersion: String?
        let minLocalizationWindowTime: TimeInterval
        let maxLocalizationWindowTime: TimeInterval
        let minFrameEvaluationScore: Float
        let minFrameEvaluationHighQualityScore: Float
    }
        
    private static let userDefaultsKey = "FantasmoSDK.RemoteConfig"
    
    private static var _config: RemoteConfig.Config!
    
    static func config() -> RemoteConfig.Config {
        guard _config == nil else {
            return _config
        }
                
        // check if we have a previously downloaded config object
        if let savedConfigData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedConfig = Config(from: savedConfigData)
        {
            log.info("successfully loaded saved remote config")
            _config = savedConfig
            return _config
        }
        
        // load the default config file from the SDK bundle
        guard let defaultConfigUrl = Bundle(for: RemoteConfig.self).url(forResource: "default-config", withExtension: "json"),
              let defaultConfig = Config(from: defaultConfigUrl)
        else {
            fatalError("failed to parse SDK default remote config")
        }
        
        _config = defaultConfig
        return defaultConfig
    }
            
    static func update(_ latest: RemoteConfig.Config) {
        _config = latest
        // save the latest config data in user defaults
        guard let configData = try? JSONEncoder().encode(latest) else {
            log.error("failed to save new remote config")
            return
        }
        log.info("successfully saved new remote config")
        UserDefaults.standard.set(configData, forKey: userDefaultsKey)
    }
}

extension RemoteConfig.Config {
    	
    init?(from fileUrl: URL) {
        guard fileUrl.isFileURL else {
            return nil
        }
        do {
            let jsonData = try Data(contentsOf: fileUrl)
            guard let instance = RemoteConfig.Config(from: jsonData) else {
                return nil
            }
            self = instance
        } catch {
            log.error("error loading remote config from file: \(fileUrl) - \(error.localizedDescription)")
            return nil
        }
    }
    
    init?(from jsonData: Data) {
        let jsonDecoder = JSONDecoder()
        jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
        do {
            self = try jsonDecoder.decode(RemoteConfig.Config.self, from: jsonData)
        } catch {
            log.error("error decoding remote json: \(error.localizedDescription)")
            return nil
        }
    }
}
