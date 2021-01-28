//
//  NetworkManager.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import Foundation

struct FMNetworkManager {
    static let networkUnavailableCode: Double = 1000
    
    // Create method for multipart image uploading
    static func uploadImage(url:String, parameters: [String : Any], jpegData:Data,
                            onCompletion: ((Int, Data?) -> Void)? = nil, onError: ((Error?) -> Void)? = nil) {
        let myUrl = NSURL(string: url);
        let request = NSMutableURLRequest(url:myUrl! as URL);
        request.httpMethod = "POST";
        
        let param = parameters
        
        let boundary = generateBoundaryString()
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        let imageData = jpegData
        
        request.httpBody = createBodyWithParameters(parameters: param, filePathKey: "image", imageDataKey: imageData, boundary: boundary, imgKey: "image") as Data
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if error != nil {
                print("error=\(error!)")
                onError?(error)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                print("statusCode: \(httpResponse.statusCode)")
                onCompletion?(httpResponse.statusCode, data)
                
            }
        }
        task.resume()
    }
    
    static func createBodyWithParameters(parameters: [String: Any]?, filePathKey: String?, imageDataKey: Data, boundary: String, imgKey: String) -> NSData {
        let body = NSMutableData();
        
        if parameters != nil {
            for (key, value) in parameters! {
                body.appendString(string: "--\(boundary)\r\n")
                body.appendString(string: "Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.appendString(string: "\(value)\r\n")
            }
        }
        
        let filename = "\(imgKey).jpg"
        let mimetype = "image/jpeg"
        
        body.appendString(string: "--\(boundary)\r\n")
        body.appendString(string: "Content-Disposition: form-data; name=\"\(filePathKey!)\"; filename=\"\(filename)\"\r\n")
        body.appendString(string: "Content-Type: \(mimetype)\r\n\r\n")
        body.append(imageDataKey)
        body.appendString(string: "\r\n")
        body.appendString(string: "--\(boundary)--\r\n")
        
        return body
    }
    
    static func generateBoundaryString() -> String {
        return "Boundary-\(UUID().uuidString)"
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
