//
//  FMSDKInfo.swift
//  FantasmoSDK
//
//  Created by Nick Jensen on 18.10.21.
//

import Foundation

public class FMSDKInfo {
    
    /// Returns the full version of a bundle represented by the "short version" (usually software version in the format "major.minor.patch") accompanied
    /// with a "CFBundleVersion" version (usually representing build number).
    /// Example: "1.0.18 (365)"
    static var fullVersion: String {
        var version = ""

        // we want the SDK bundle, not the host `main` bundle
        let bundle = Bundle(for: FMSDKInfo.self)

        if let shortBundleVersion = bundle.infoDictionary?["CFBundleShortVersionString"] as? String {
            version += shortBundleVersion
        }

        if let buildVersion = bundle.infoDictionary?["CFBundleVersion"] as? String {
            version += " (" + buildVersion + ")"
        }

        return version
    }
}
