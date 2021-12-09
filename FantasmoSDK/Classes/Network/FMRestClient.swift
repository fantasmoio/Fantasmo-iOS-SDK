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
        case badRequest
        case badResponse
    }
    
    typealias RestResult = (Int?, Data?) -> Void
    typealias RestError = (Error) -> Void
    
    // MARK: - internal methods

    /// Make a POST request with parameters encoded as JSON
    ///
    /// - Parameters:
    ///   - endpoint: The API endpoint to post to
    ///   - parameters: Parameters to be JSON encoded and sent in the request body
    ///   - token: Optional API security token
    ///   - completion: Completion closure
    ///   - error: Error closure
    static func post(_ endpoint: FMApiRouter.ApiEndpoint,
                     parameters: [String: Any],
                     token: String?,
                     completion: RestResult? = nil,
                     error: RestError? = nil) {
        
        var request = Self.postRequestForEndpoint(endpoint, token: token)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        log.info(String(describing: request.url), parameters: parameters)
                
        guard let jsonData = try? JSONSerialization.data(withJSONObject: parameters, options: []) else {
            let badRequestError = FMError(RestClientError.badRequest)
            log.error(badRequestError)
            error?(badRequestError)
            return
        }
        
        Self.post(data: jsonData, with: request, completion: completion, error: error)
    }
    
    /// Make a POST request with image data and parameters
    ///
    /// - Parameters:
    ///   - endpoint: The API endpoint to post to
    ///   - parameters: Dictionary of form parameters
    ///   - imageData: Image as JPEG data that should be added to the body of the request along with passed `parameters`
    ///   - token: Optional API security token
    ///   - completion: Completion closure
    ///   - error: Error closure
    static func post(_ endpoint: FMApiRouter.ApiEndpoint,
                     parameters: [String : String?],
                     imageData: Data,
                     token: String?,
                     completion: RestResult? = nil,
                     error: RestError? = nil) {
        
        var request = Self.postRequestForEndpoint(endpoint, token: token)
        request.setValue("multipart/form-data; boundary=\(Data.boundary)", forHTTPHeaderField: "Content-Type")
        log.info(String(describing: request.url), parameters: parameters)
        
        var data = Data()
        data.appendParameters(parameters)
        data.appendImage(imageData)
        data.appendFinalBoundary()
        
        Self.post(data: data, with: request, completion: completion, error: error)
    }
    
    // MARK: - private methods

    /// Does the actual work of posting to the CPS server
    ///
    /// - Parameters:
    ///   - data: Multipart-form data to post
    ///   - request: Request containing server URL, endpoint, and token
    ///   - completion: Completion closure
    ///   - error: Error closure
    private static func post(data: Data,
                             with request: URLRequest,
                             completion: RestResult? = nil,
                             error: RestError? = nil) {
        let session = URLSession.shared
        session.uploadTask(with: request, from: data, completionHandler: { data, response, uploadError in
            guard let data = data, let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    let uploadError = FMError(RestClientError.badResponse, cause: uploadError)
                    log.error(uploadError)
                    error?(uploadError)
                }
                return
            }
            DispatchQueue.main.async {
                completion?(response.statusCode, data)
            }
        }).resume()
    }

    /// Generates a request that can be used for posting
    ///
    /// - Parameters:
    ///   - endpoint: The API endpoint to post to
    ///   - token: Optional API security token
    /// - Returns: POST request containing server URL, endpoint, token header, and `multipart/from-data` header
    private static func postRequestForEndpoint(_ endpoint: FMApiRouter.ApiEndpoint, token: String?) -> URLRequest {
        var request = URLRequest(url: FMApiRouter.urlForEndpoint(endpoint))
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        request.httpMethod = "POST"
        if let token = token {
            request.setValue(token, forHTTPHeaderField: "Fantasmo-Key")
        }
        return request
    }
}

// MARK: - private Data extension

/// Multipart form extension
/// Provides methods required for preparing data for a `multipart/form-data` transaction
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
    
    mutating func appendParameters(_ params: [String : String?]) {
        for (key, value) in params {
            if let value = value {
                self.appendParameter(key, value: value)
            }
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
