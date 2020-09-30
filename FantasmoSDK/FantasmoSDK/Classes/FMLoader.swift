//
//  Loader.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import Foundation
import CoreLocation
import ARKit

public class FMLoader: NSObject {
    /**
     Loader method for initialize swizzle method.
     */
    @objc public static func swiftyLoad() {
        CLLocationManager.swizzle()
        ARSession.swizzle()
    }
}
