//
//  UIDevice+Extension.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 13.07.2021.
//

import UIKit

extension UIDevice {
    
    /// Gets the identifier from the system, such as "iPhone7,1".
    /// Device model by identifier can be found at https://en.wikipedia.org/wiki/List_of_iOS_and_iPadOS_devices
    var identifier: String {
        UIDevice.cachedIdentifier
    }
    
    /// The name of the operating system running on the device represented by the receiver (e.g. "iOS", "tvOS" or "iPadOS").
    /// - Note:`UIDevice.systemName` property has a drawback returning "iOS" when "iPadOS" is expected.
    var correctedSystemName: String {
        if #available(iOS 13, *),
           UIDevice.current.systemName == "iOS",
           UIDevice.current.userInterfaceIdiom == .pad {
            return "iPadOS"
        } else {
            return UIDevice.current.systemName
        }
    }
    
    // MARK: - Helpers
    
    private static var cachedIdentifier: String = {
        var systemInfo = utsname()
        uname(&systemInfo)
        let mirror = Mirror(reflecting: systemInfo.machine)
        
        let identifier = mirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }()
    
}
