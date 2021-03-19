//
//  FMRestClient.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/18/21.
//

import Foundation

struct FMRestClient {
    
    static let crlf = "\r\n"
    static let boundary = "ce8f07c0c2d14f0bbb1e3a96994e0354"
    
    struct BoundaryGenerator {
        enum BoundaryType {
            case initial, middle, final
        }
        
        static func boundaryData(_ type: BoundaryType) -> Data {
            let boundaryText: String
            
            switch type {
            case .initial:
                boundaryText = "--\(boundary)\(crlf)"
            case .middle:
                boundaryText = "\(crlf)--\(boundary)\(crlf)"
            case .final:
                boundaryText = "\(crlf)--\(boundary)--\(crlf)"
            }
            
            return Data(boundaryText.utf8)
        }
    }
    
    enum RestClientError: Error {
        case badResponse
    }
    
    typealias RestResult = (Int?, Data?) -> Void
    typealias RestError = (Error) -> Void
    
    static func post(_ endpoint: FMApiRouter.ApiEndpoint,
                     parameters: [String : String],
                     token: String?,
                     completion: RestResult? = nil,
                     error: RestError? = nil) {
        
        let request = Self.requestForEndpoint(endpoint, token: token)
        var data = Data()
        data.appendParameters(parameters)
        data.appendFinalBoundary()
        Self.post(data: data, with: request, completion: completion, error: error)
    }
    
    static func post(_ endpoint: FMApiRouter.ApiEndpoint,
                     parameters: [String : String],
                     imageData: Data,
                     token: String?,
                     completion: RestResult? = nil,
                     error: RestError? = nil) {
        
        let request = Self.requestForEndpoint(endpoint, token: token)
        var data = Data()
        data.appendParameters(parameters)
        data.appendFinalBoundary()
        //TODO: append image
        Self.post(data: data, with: request, completion: completion, error: error)
    }
    
    private static func post(data: Data, with request: URLRequest, completion: RestResult? = nil, error: RestError? = nil) {

        let session = URLSession.shared
        session.uploadTask(with: request, from: data, completionHandler: { data, response, errorResponse in
            guard let data = data, let response = response as? HTTPURLResponse else {
                error?(RestClientError.badResponse)
                return
            }
            completion?(response.statusCode, data)
        }).resume()
    }
    
    private static func requestForEndpoint(_ endpoint: FMApiRouter.ApiEndpoint, token: String?) -> URLRequest {
        var request = URLRequest(url: FMApiRouter.urlForEndpoint(endpoint))
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.httpMethod = "POST"
        if let token = token {
            request.setValue(token, forHTTPHeaderField: "Fantasmo-Key")
        }
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        return request
    }
}

extension Data {
    mutating func appendParameters(_ params: [String : String]) {
        for (key, value) in params {
            self.appendParameter(key, value: value)
        }
    }
    
    mutating func appendParameter(_ name: String, value: String) {
        self.append(FMRestClient.BoundaryGenerator.boundaryData(.middle))
        self.append("Content-Disposition: form-data; name=\"\(name)\"\(FMRestClient.crlf)\(FMRestClient.crlf)".data(using: .utf8)!)
        self.append(value.data(using: .utf8)!)
    }
    
    mutating func appendFinalBoundary() {
        self.append(FMRestClient.BoundaryGenerator.boundaryData(.final))
    }
}
