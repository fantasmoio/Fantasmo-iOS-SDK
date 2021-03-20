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

    //TODO: move to location class after cleaning up swizzling
    /**
     Current location
     */
    struct Location {
        static var current: CLLocation {
            get {
                if let override = FMConfiguration.stringForInfoKey(.gpsLatLong) {
                    print("FMConfiguration using location override: \(override)")
                    let components = override.components(separatedBy:",")
                    if let latitude = Double(components[0]), let longitude = Double(components[1]) {
                        return CLLocation(latitude: latitude, longitude: longitude)
                    } else {
                        return CLLocation()
                    }
                } else {
                    return CLLocationManager.lastLocation ?? CLLocation()
                }
            }
        }
    }
}
