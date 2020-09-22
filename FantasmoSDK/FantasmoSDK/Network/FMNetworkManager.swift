//
//  NetworkManager.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireObjectMapper
import BrightFutures
import ObjectMapper

struct FMNetworkManager {
    static let networkUnavailableCode: Double = 1000

    static let networkQueue = DispatchQueue(label: "\(String(describing: Bundle.main.bundleIdentifier)).networking-queue", attributes: .concurrent)
    
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
    
    static func error(fromResponseObject responseObject: DataResponse<Any, AFError>) -> Error? {
        if let statusCode = responseObject.response?.statusCode {
            switch statusCode {
            case 200...300: return nil
            default:
                if let result = responseObject.result.value as? [String: Any],
                    let errorMessage = result["error"] as? String {
                    if let code = result["code"] as? Double {
                        return NetworkError.error(code: code, message: errorMessage)
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
                return NetworkError.error(code: Double(statusCode), message: jsonString)
            }
        } else {
            let code = (error as NSError).code
            switch code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorCannotConnectToHost, NSURLErrorCannotFindHost:
                return NetworkError.error(code: FMNetworkManager.networkUnavailableCode, message: Errors.networkUnreachableError)
            default:
                return NetworkError.errorString(Errors.genericError)
            }
        }
        return NetworkError.errorString(Errors.genericError)
    }
    
    static func uploadImage(url:String, parameters: [String : Any], image:FMImage, jpegData:Data, mapName:String,
                            onCompletion: ((Data?) -> Void)? = nil, onError: ((Error?) -> Void)? = nil) {
        let headers: HTTPHeaders = [
            "Content-type": "multipart/form-data"
        ]
        
        AF.upload(multipartFormData: { (multipartFormData) in
            for (key, value) in parameters {
                multipartFormData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key as String)
            }
            multipartFormData.append("\(NSDate().timeIntervalSince1970)".data(using: String.Encoding.utf8)!, withName: "capturedAt" as String)
            multipartFormData.append("\(image.uuid)".data(using: String.Encoding.utf8)!, withName: "uuid" as String)
            multipartFormData.append(mapName.data(using: String.Encoding.utf8)!, withName: "mapId" as String)
            multipartFormData.append(jpegData, withName: "image", fileName: "image.jpg", mimeType: "image/jpeg")
        }, to: url, usingThreshold: UInt64.init(), method: .post, headers: headers).response  { (result) in
            print(result)
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

enum NetworkError: FantasmoLocalizedError {
    
    case errorString(String)
    case error(code: Double?, message: String)
    case generic
    
    var errorDescription: String? {
        switch self {
        case .errorString(let errorMessage): return errorMessage
        case .error(_,let message): return message
        case .generic: return Errors.genericError
        }
    }
    
    var info: (code: Double?, message: String) {
        switch self {
        case .error(let code, let message):
            return (code, message)
        case .errorString(let errorMessage): return (nil, errorMessage)
        case .generic: return  (nil, Errors.genericError)
        }
    }
}

protocol FantasmoLocalizedError: LocalizedError {
    var title: String { get }
    var localDescription: String { get }
}

extension FantasmoLocalizedError {
    var title: String {
        return ""
    }
    
    var localDescription : String {
        return ""
    }
}

struct Errors {
    static let genericError = "Something went wrong. Please try again."
    static let networkUnreachableError  = "No internet connection. Please try again later."
}
