//
//  Constant.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import Foundation
import CoreLocation

public struct FMConfiguration {
    
    /**
     Info.plist keys used for configuration
     */
    enum infoKeys: String {
        case apiBaseUrl = "FM_API_BASE_URL"
        case gpsLatLong = "FM_GPS_LAT_LONG"
        case accessToken = "FM_ACCESS_TOKEN"
    }

    private static var _accessToken: String?
    
    /// Sets your Fantasmo access token.
    ///
    /// Note: Access tokens set via `setAccessToken(_:)` method override tokens listed in your app's Info.plist
    public static func setAccessToken(_ accessToken: String) {
        _accessToken = accessToken
    }
    
    /// Returns the current Fantasmo access token set either via `setAccessToken(_:)` or that is listed your app's Info.plist
    ///
    /// Note: Access tokens set via `setAccessToken(_:)` method override tokens listed in your app's Info.plist
    public static func accessToken() -> String {
        if let accessToken = _accessToken {
            return accessToken
        }
        if let accessToken = stringForInfoKey(.accessToken) {
            return accessToken
        }
        fatalError("Missing or invalid access token. Please add an access token to the Info.plist with the following key: \(infoKeys.accessToken.rawValue) or set one with `FMConfiguration.setAccessToken(_:)`")
    }
    
    /**
     Get optional int from Info.plist by key
     */
    static func intForInfoKey(_ key: infoKeys) -> Int? {
        if let info = Bundle.main.object(forInfoDictionaryKey: key.rawValue) as? Int {
            return info
        } else {
            return nil
        }
    }
    
    /**
     Get optional string from Info.plist by key
     */
    static func stringForInfoKey(_ key: infoKeys) -> String? {
        if let info = Bundle.main.object(forInfoDictionaryKey: key.rawValue) as? String, info.count > 0 {
            return info
        } else {
            return nil
        }
    }
}
