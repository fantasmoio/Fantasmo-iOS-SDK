//
//  FMApiRouter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/19/21.
//

import Foundation

struct FMApiRouter {
    
    enum ApiVersion {
        
        case v1
        case v2
        
        var baseUrl: URL {
            let urlString: String
            if let overrideUrlString = FMConfiguration.stringForInfoKey(.apiBaseUrl) {
                log.warning("Using base url override", parameters: ["override": overrideUrlString])
                urlString = overrideUrlString
            } else {
                urlString = "https://api.fantasmo.io"
            }
            guard let url = URL(string: urlString) else {
                fatalError("api base url is invalid")
            }
            let version: String
            switch self {
            case .v1:
                version = "v1"
            case .v2:
                version = "v2"
            }
            return url.appendingPathComponent(version)
        }
    }
    
    enum ApiEndpoint {
        
        case isLocalizationAvailable
        case initialize
        case localize
        
        var path: String {
            switch self {
            case .isLocalizationAvailable:
                return "isLocalizationAvailable"
            case .initialize:
                return "initialize"
            case .localize:
                return "image.localize"
            }
        }
        
        var url: URL {
            let apiVersion: ApiVersion
            switch self {
            case .initialize, .isLocalizationAvailable:
                apiVersion = .v2
            case .localize:
                apiVersion = .v1
            }
            return apiVersion.baseUrl.appendingPathComponent(self.path)
        }
    }
}
