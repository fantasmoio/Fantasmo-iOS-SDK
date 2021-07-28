//
//  HttpMethod.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 27.07.2021.
//

import Foundation

public struct HTTPMethod: RawRepresentable, Equatable, Hashable {
    
    /// `GET` method.
    public static let get = HTTPMethod(rawValue: "GET")
    
    /// `POST` method.
    public static let post = HTTPMethod(rawValue: "POST")
    
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
}
