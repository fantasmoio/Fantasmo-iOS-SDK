//
//  NetworkManager.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import Foundation
import Alamofire
import BrightFutures

struct FMNetworkManager {
    static let networkUnavailableCode: Double = 1000

    static let networkQueue = DispatchQueue(label: "\(String(describing: Bundle.main.bundleIdentifier)).networking-queue", attributes: .concurrent)
    
    //Make request for alamofire url request
    static func makeRequest(_ urlRequest: URLRequestConvertible, showLog: Bool = false, completion: @escaping (NetworkResult) -> ()) {
        AF.request(urlRequest).responseJSON { responseObject in
            switch responseObject.result {
            case .success(let value):
                debugPrint("URL: \(urlRequest.urlRequest?.url?.absoluteString ?? "")")
                
                if (showLog) {
                    debugPrint("Response: \(value)")
                }
                
                if let error = error(fromResponseObject: responseObject) {
                    completion(.failure(error))
                } else {
                    completion(.success(value))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    // Return error from response
    static func error(fromResponseObject responseObject: DataResponse<Any, AFError>) -> Error? {
        if let statusCode = responseObject.response?.statusCode {
            switch statusCode {
            case 200...300: return nil
            default:
                if let result = responseObject.result.value as? [String: Any],
                    let errorMessage = result["error"] as? String {
                    if let code = result["code"] as? Double {
                        return NetworkError.custom(code: code, message: errorMessage)
                    } else {
                        return NetworkError.errorString(errorMessage)
                    }
                }
            }
        }
        return NetworkError.errorString(Errors.genericError)
    }
    
    private func generateError(from error: Error, with responseObject: DataResponse<Any, AFError>) -> Error {
        if let statusCode = responseObject.response?.statusCode {
            if let data = responseObject.data, let jsonString = String(data: data, encoding: .utf8) {
                return NetworkError.custom(code: Double(statusCode), message: jsonString)
            }
        } else {
            let code = (error as NSError).code
            switch code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorCannotConnectToHost, NSURLErrorCannotFindHost:
                return NetworkError.custom(code: FMNetworkManager.networkUnavailableCode, message: Errors.networkUnreachableError)
            default:
                return NetworkError.errorString(Errors.genericError)
            }
        }
        return NetworkError.errorString(Errors.genericError)
    }
    
    // Create method for multipart image uploading
    static func uploadImage(url:String, parameters: [String : Any], jpegData:Data,
                            onCompletion: ((Data?) -> Void)? = nil, onError: ((Error?) -> Void)? = nil) {
        let headers: HTTPHeaders = [
            "Content-type": "multipart/form-data"
        ]
        
        AF.upload(multipartFormData: { (multipartFormData) in
            for (key, value) in parameters {
                multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as String)
            }
            multipartFormData.append(jpegData, withName: "image", fileName: "image.jpg", mimeType: "image/jpeg")
        }, to: url, usingThreshold: UInt64.init(), method: .post, headers: headers).response  { (result) in
            if result.error != nil {
                onError?(result.error)
            }
            
            onCompletion?(result.data)            
        }
    }
}

enum NetworkResult {
    case success(Any)
    case failure(Error)
    
    var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }
    
    var isFailure: Bool {
        return !isSuccess
    }
    
    var value: Any? {
        switch self {
        case .success(let value):
            return value
        case .failure:
            return nil
        }
    }
    
    var error: Error? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}
