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

struct FMSessionFrameEvaluations {
    let count: Int
    let type: FMFrameEvaluationType
    let highestScore: Float
    let lowestScore: Float
    let averageScore: Float
    let averageTime: TimeInterval
    let userInfo: [String: String]?
}

struct FMSessionFrameRejections {
    let count: Int
    let rejectionReasons: [FMFrameRejectionReason: Int]
}

struct FMSessionAnalytics {
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
