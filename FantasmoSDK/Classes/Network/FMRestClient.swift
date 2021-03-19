//
//  FMRestClient.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/18/21.
//

import Foundation

struct FMRestClient {
    typealias RestResult = (Int?, Data?) -> Void
    typealias RestError = (Error) -> Void
    
    static func post(_ endpoint: FMApiRouter.ApiEndpoint,
                     parameters: [String : String],
                     token: String?,
                     completion: RestResult? = nil,
                     error: RestError? = nil) {
        
    }
    
    static func post(_ endpoint: FMApiRouter.ApiEndpoint,
                     parameters: [String : String],
                     imageData: Data,
                     token: String?,
                     completion: RestResult? = nil,
                     error: RestError? = nil) {
        
    }
}
