//
//  FMApiRouter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/19/21.
//

import Foundation

struct FMApiRouter {
    enum ApiEndpoint: String {
        case localize = "image.localize"
        case zoneInRadius = "parking.in.radius"
    }
    
    static var apiBaseUrl: String {
        get {
            if let override = FMConfiguration.stringForInfoKey(.apiBaseUrl) {
                print("FMConfiguration using url override: \(override)")
                return "http://\(override)"
            } else {
                return "https://api.fantasmo.io/v1/"
            }
        }
    }
    
    static func urlForEndpoint(_ endpoint: ApiEndpoint) -> URL {
        return URL(string: Self.apiBaseUrl)!.appendingPathComponent(endpoint.rawValue)
    }
}
