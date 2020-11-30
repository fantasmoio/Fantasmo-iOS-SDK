//
//  Loader.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import Foundation
import CoreLocation
import ARKit
import CocoaLumberjack

public class FMLoader: NSObject {
    /**
     Loader method for initialize swizzle method.
     */
    @objc public static func swiftyLoad() {
        DDLog.add(DDOSLogger.sharedInstance) // Uses os_log

        let fileLogger: DDFileLogger = DDFileLogger()
        fileLogger.rollingFrequency = 60 * 60 * 24
        fileLogger.logFileManager.maximumNumberOfLogFiles = 7
        DDLog.add(fileLogger)
        
        DDLogInfo("Fantasmo SDK loaded")
        
        CLLocationManager.swizzle()
        ARSession.swizzle()
    }
}
