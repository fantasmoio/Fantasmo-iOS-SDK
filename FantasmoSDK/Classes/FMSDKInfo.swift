//
//  FMSDKInfo.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 18.10.21.
//

import Foundation

public class FMSDKInfo {
    
    /// Returns the FantasmoSDK framework version as a string in the format "major.minor.patch".
    /// Example: "2.0.1".
    static var fullVersion: String {
        var version = ""

        // we want the SDK bundle, not the host `main` bundle
        let bundle = Bundle(for: FMSDKInfo.self)
        
        if let marketingVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String {
            version += marketingVersion
        }

        return version
    }
}
