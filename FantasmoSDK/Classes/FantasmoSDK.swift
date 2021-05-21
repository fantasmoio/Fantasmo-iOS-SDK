//
//  FantasmoSDK.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 02.05.2021.
//

import Foundation

public class FantasmoSDK {
    
    /// Initialize the SDK.
    /// You must call this method before calling any other SDK API.
    /// This method should be called from your application AppDelegate.
    ///
    ///  - Parameter apiKey: The API key that authenticates requests associated with your project and which you get from Fantasmo.io.
    public static func initialize(withApiKey apiKey: String) {
        FMApi.shared.apiKey = apiKey
    }
    
}
