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
                log.warning("Using url override", parameters: ["override": overrideUrlString])
                urlString = "http://\(overrideUrlString)"
            } else {
                switch self {
                case .v1:
                    urlString = "https://api.fantasmo.io/v1/"
                case .v2:
                    urlString = "https://mobility-bff-dev.fantasmo.dev/v2/"
                }
            }
            guard let url = URL(string: urlString) else {
                fatalError("api base url is invalid")
            }
            return url
        }
    }
    
    enum ApiEndpoint {
        
        case initialize
        case localize
        
        var path: String {
            switch self {
            case .initialize:
                return "initialize"
            case .localize:
                return "image.localize"
            }
        }
        
        var url: URL {
            let apiVersion: ApiVersion
            switch self {
            case .initialize:
                apiVersion = .v2
            case .localize:
                apiVersion = .v1
            }
            return apiVersion.baseUrl.appendingPathComponent(self.path)
        }
    }
}
