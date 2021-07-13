//
//  Bundle+Extension.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 13.07.2021.
//

import Foundation

extension Bundle {
    
    /// Returns the full version of a bundle represented by software version accompanied with a build version.
    /// Example: "1.0.18(365)"
    static var fullVersion: String {
        var version = ""
        if let shortBundleVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            version += shortBundleVersion
        }
        if let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            version += buildVersion
        }
        return version
    }
    
}
