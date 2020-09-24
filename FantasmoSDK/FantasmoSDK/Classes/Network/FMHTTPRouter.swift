//
//  HttpRouter.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import Foundation
import Alamofire

// Protocol that allows us to get a base URL, path, request type, parameter, header and URLRequest  for our application
protocol FMHTTPRouter: URLRequestConvertible {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: [String: Any]? { get }
    var headers: [String: String]? { get }
    var request: URLRequest { get }
}

extension FMHTTPRouter {
    
    // MARK: - BaseURL
    var baseURL: String {
        return FMConfiguration.Server.routeUrl
    }
    
    // MARK: - URL
    var url: URL {
        return URL(string: baseURL + path)!
    }
    
    // MARK: - Paramter
    var parameters: [String: Any]? {
        return nil
    }
    
    // MARK: - Header
    var headers: [String : String]? {
        return nil
    }
    
    // MARK: URLRequestConvertible
    var request: URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        return urlRequest
    }
}
