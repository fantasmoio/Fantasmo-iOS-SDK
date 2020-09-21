//
//  HttpRouter.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import Foundation
import Alamofire

protocol HTTPRouter: URLRequestConvertible {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: [String: Any]? { get }
    var headers: [String: String]? { get }
    var request: URLRequest { get }
}

extension HTTPRouter {
    
    var baseURL: String {
        return Server.Constants.routeUrl
    }
    
    var url: URL {
        return URL(string: baseURL + path)!
    }
    
    var parameters: [String: Any]? {
        return nil
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    var request: URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return urlRequest
    }
}
