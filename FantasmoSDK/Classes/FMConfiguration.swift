//
//  Constant.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import Foundation
import CoreLocation

struct FMConfiguration {

    /**
     Info.plist keys used for configuration
     */
    enum infoKeys: String {
        case apiBaseUrl = "FM_API_BASE_URL"
        case gpsLatLong = "FM_GPS_LAT_LONG"
        case accessToken = "FM_ACCESS_TOKEN"
    }

    static func accessToken() -> String {
        guard let accessToken = stringForInfoKey(.accessToken) else {
            fatalError("Missing or invalid access token. Please add an access token to the Info.plist with the following key: \(infoKeys.accessToken.rawValue)")
        }
        return accessToken
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
