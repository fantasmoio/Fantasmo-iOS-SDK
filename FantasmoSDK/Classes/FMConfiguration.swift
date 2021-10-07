//
//  Constant.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import Foundation
import CoreLocation

internal struct FMConfiguration {

    /**
     Info.plist keys used for configuration
     */
    enum infoKeys: String {
        case apiBaseUrl = "FM_API_BASE_URL"
        case gpsLatLong = "FM_GPS_LAT_LONG"
        case accessToken = "FM_ACCESS_TOKEN"
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
