//
//  FMRestClient.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/18/21.
//

import Foundation

/// REST client for communication wiht CPS server
/// Only supports POST with multipart-form data, as that's what the server needs
struct FMRestClient {
    
    enum RestClientError: Error {
        case badResponse
    }
    
    typealias RestResult = (Int?, Data?) -> Void
    typealias RestError = (Error) -> Void
    
    // MARK: - internal methods
    
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
        data.appendImage(imageData)
        data.appendFinalBoundary()
        Self.post(data: data, with: request, completion: completion, error: error)
    }
    
    // MARK: - private methods
    
    private static func post(data: Data, with request: URLRequest, completion: RestResult? = nil, error: RestError? = nil) {

        let session = URLSession.shared
        session.uploadTask(with: request, from: data, completionHandler: { data, response, taskError in
            guard let data = data, let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    error?(FMError(RestClientError.badResponse, cause: taskError))
                }
                return
            }
            DispatchQueue.main.async {
                completion?(response.statusCode, data)
            }
        }).resume()
    }
    
    private static func requestForEndpoint(_ endpoint: FMApiRouter.ApiEndpoint, token: String?) -> URLRequest {
        var request = URLRequest(url: FMApiRouter.urlForEndpoint(endpoint))
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.httpMethod = "POST"
        if let token = token {
            request.setValue(token, forHTTPHeaderField: "Fantasmo-Key")
        }
        request.setValue("multipart/form-data; boundary=\(Data.boundary)", forHTTPHeaderField: "Content-Type")
        return request
    }
}

// MARK: - private Data extension

/// Multipart form extension
private extension Data {
    static let crlf = "\r\n"
    static let crlf2x = crlf + crlf
    static let boundary = "ce8f07c0c2d14f0bbb1e3a96994e0354"

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
    
    mutating func appendParameters(_ params: [String : String]) {
        for (key, value) in params {
            self.appendParameter(key, value: value)
        }
    }
    
    mutating func appendParameter(_ name: String, value: String) {
        self.append(Self.boundaryData(.middle))
        self.append("Content-Disposition: form-data; name=\"\(name)\"\(Self.crlf2x)".data(using: .utf8)!)
        self.append(value.data(using: .utf8)!)
    }
    
    mutating func appendImage(_ imageData: Data) {
        self.append(Self.boundaryData(.middle))
        self.append("Content-Disposition: form-data; name=\"image\"; filename=\"image.jpg\"\(Self.crlf)".data(using: .utf8)!)
        self.append("Content-Type: image/jpeg\(Self.crlf2x)".data(using: .utf8)!)
        self.append(imageData)
    }
    
    mutating func appendFinalBoundary() {
        self.append(Self.boundaryData(.final))
    }
}
