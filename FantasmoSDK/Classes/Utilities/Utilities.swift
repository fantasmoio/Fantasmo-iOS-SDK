//
//  Utilities.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 12.07.2021.
//

import Foundation

struct Utilities {
    
    static var bundleVersion: String {
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
