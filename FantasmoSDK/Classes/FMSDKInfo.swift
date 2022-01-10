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
    
    /// Returns the host app's bundle identifer.
    /// Example: "com.example.MyApp"
    static var hostAppBundleIdentifier: String {
        return Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
    }
    
    /// Returns the host app's marketing version as a string in the format "major.minor.patch".
    /// Example: "2.0.1".
    static var hostAppMarketingVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    /// Returns the host app's build number as a string.
    /// Example: "123"
    static var hostAppBuildNumber: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
}
