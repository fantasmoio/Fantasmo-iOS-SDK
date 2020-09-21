//
//  FantasmoHttpRouter.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import UIKit
import Foundation
import Alamofire

enum FantasmoHttpRouter: HTTPRouter {
    
    case getLocation(location: String)

    var path: String {
        switch self {
        case .getLocation:
            return "location"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        default:
            return .get
        }
    }
    
    var jsonParameters: [String: Any]? {
        switch self {
        case .getLocation(let location):
            return ["location" :location]
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        switch self {
        default:
            return try URLEncoding.queryString.encode(request, with: jsonParameters)
        }
    }
}
