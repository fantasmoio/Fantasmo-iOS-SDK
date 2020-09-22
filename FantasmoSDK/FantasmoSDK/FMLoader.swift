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
    @objc public static func swiftyLoad() {
        ARSession.swizzle()
    }
}
