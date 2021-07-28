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

    /// Post a query with an optional image to the CPS server
    ///
    /// - Parameters:
    ///   - endpoint: The API endpoint to post to
    ///   - parameters: Dictionary of form parameters
    ///   - imageData: Image as JPEG data that should be added to the body of the request along with passed `parameters`
    ///   - token: Optional API security token
    ///   - completion: Completion closure
    ///   - error: Error closure
    static func post(urlRequest: URLRequest,
                     parameters: [String : String],
                     completion: RestResult? = nil,
                     errorClosure: RestError? = nil) {
        do {
            var data = Data()
            try data.appendParameters(parameters)
            data.appendFinalBoundary()
            
            Self.post(data: data, urlRequest: urlRequest, completion: completion, errorClosure: errorClosure)
        }
        catch {
            errorClosure?(error)
        }
    }
    
    /// - throws:  An `ApiError` if multipart forma data encoding encounters an error.
    static func post(urlRequest: URLRequest,
                     multipartFormData: MultipartFormData,
                     completion: RestResult? = nil,
                     errorClosure: RestError? = nil) {
        do {
            let bodyData = try multipartFormData.encode()
            Self.post(data: bodyData, urlRequest: urlRequest, completion: completion, errorClosure: errorClosure)
        }
        catch {
            errorClosure?(error)
        }
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
                             urlRequest: URLRequest,
                             completion: RestResult? = nil,
                             errorClosure: RestError? = nil) {
        let session = URLSession.shared
        session.uploadTask(with: urlRequest, from: data, completionHandler: { data, response, uploadError in
            guard let data = data, let response = response as? HTTPURLResponse else {
                DispatchQueue.main.async {
                    let uploadError = FMError(RestClientError.badResponse, cause: uploadError)
                    log.error(uploadError)
                    errorClosure?(uploadError)
                }
                return
            }
            DispatchQueue.main.async {
                completion?(response.statusCode, data)
            }
        }).resume()
    }

}
