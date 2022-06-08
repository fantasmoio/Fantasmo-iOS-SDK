//
//  Settings.swift
//  FantasmoSDKTestHarness
//
//  Created by Nick Jensen on 02.11.21.
//

import Foundation
import FantasmoSDK

class Settings {
    
    enum Key: String {
        case localizeForever
        case desiredResultConfidence
        case maxErrorResults
    }

    static var localizeForever: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: Key.localizeForever.rawValue)
        }
        get {
            return UserDefaults.standard.object(forKey: Key.localizeForever.rawValue) as? Bool ?? false
        }
    }
    
    static var maxErrorResults: Int {
        set {
            UserDefaults.standard.set(newValue, forKey: Key.maxErrorResults.rawValue)
        }
        get {
            return UserDefaults.standard.object(forKey: Key.maxErrorResults.rawValue) as? Int ?? 10
        }
    }
    
    static func setDesiredResultConfidence(_ confidence: FMResultConfidence) {
        UserDefaults.standard.set(confidence.description, forKey: Key.desiredResultConfidence.rawValue)
    }
    
    static var desiredResultConfidence: FMResultConfidence {
        let value = UserDefaults.standard.string(forKey: Key.desiredResultConfidence.rawValue) ?? ""
        let confidence: FMResultConfidence
        switch value {
        case FMResultConfidence.low.description:
            confidence = .low
        case FMResultConfidence.medium.description:
            confidence = .medium
        case FMResultConfidence.high.description:
            confidence = .high
        default:
            confidence = .high
        }
        return confidence
    }
}
