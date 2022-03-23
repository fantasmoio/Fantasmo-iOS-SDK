//
//  FMAnalytics.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 22.03.22.
//

import Foundation
import CoreLocation


struct FMImageEnhancementInfo: Codable {
    var gamma: Float
}


struct FMRotationSpread: Codable {
    var pitch: Float
    var yaw: Float
    var roll: Float
}


struct FMLegacyFrameEvents {
    var excessiveTilt: Int
    var excessiveBlur: Int
    var excessiveMotion: Int
    var insufficientFeatures: Int
    var lossOfTracking: Int
    var total: Int
}


struct FMFrameResolution: Codable {
    var height: Int
    var width: Int
}


struct FMLocalizationAnalytics {
    var appSessionId: String?
    var appSessionTags: [String]?
    var localizationSessionId: String?
    var legacyFrameEvents: FMLegacyFrameEvents
    var rotationSpread: FMRotationSpread
    var totalDistance: Float
    var magneticField: MotionManager.MagneticField?
    var imageEnhancementInfo: FMImageEnhancementInfo?
    var remoteConfigId: String
}


struct FMImageQualityUserInfo: Encodable {
    let modelVersion: String
    let error: String?
    
    enum CodingKeys: String, CodingKey {
        case modelVersion
        case error
    }
    
    init(modelVersion: String? = nil, error: String? = nil) {
        self.modelVersion = modelVersion ?? ""
        self.error = error
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(modelVersion, forKey: .modelVersion)
        try container.encodeIfPresent(error, forKey: .error)
    }
}


struct FMSessionFrameEvaluations: Encodable {
    let count: Int
    let type: FMFrameEvaluationType
    let highestScore: Float
    let lowestScore: Float
    let averageScore: Float
    let averageTime: TimeInterval
    let imageQualityUserInfo: FMImageQualityUserInfo?
    
    enum CodingKeys: String, CodingKey {
        case count
        case type
        case highestScore
        case lowestScore
        case averageScore
        case averageTime
        case imageQualityUserInfo
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(count, forKey: .count)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(highestScore, forKey: .highestScore)
        try container.encode(lowestScore, forKey: .lowestScore)
        try container.encode(averageScore, forKey: .averageScore)
        try container.encode(averageTime, forKey: .averageTime)
        try container.encodeIfPresent(imageQualityUserInfo, forKey: .imageQualityUserInfo)
    }
}


struct FMSessionFrameRejections: Encodable {
    let count: Int
    let rejectionReasons: [FMFrameRejectionReason: Int]
    
    enum CodingKeys: String, CodingKey {
        case count
        case rejectionReasons
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(count, forKey: .count)
        var rejectionReasonDict: [String: Int] = [:]
        rejectionReasons.forEach { key, value in
            rejectionReasonDict[key.rawValue] = value
        }
        try container.encode(rejectionReasonDict, forKey: .rejectionReasons)
    }
}

struct FMSessionAnalytics: Encodable {
    let localizationSessionId: String
    let appSessionId: String
    let appSessionTags: [String]
    let totalFrames: Int
    let totalFramesUploaded: Int
    let frameEvaluations: FMSessionFrameEvaluations
    let frameRejections: FMSessionFrameRejections
    let locationResultCount: Int
    let errorResultCount: Int
    let totalTranslation: Float
    let rotationSpread: FMRotationSpread
    let timestamp: TimeInterval
    let totalDuration: TimeInterval
    let location: CLLocation
    let remoteConfigId: String
    let udid: String
    let deviceModel: String
    let deviceOs: String
    let deviceOsVersion: String
    let sdkVersion: String
    let hostAppBundleIdentifier: String
    let hostAppMarketingVersion: String
    let hostAppBuild: String
}
