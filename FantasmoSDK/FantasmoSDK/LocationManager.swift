//
//  LocationManager.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import Foundation
import CoreLocation

private var locationDeleage: CLLocationManagerDelegate?

extension CLLocationManager : CLLocationManagerDelegate {
    @objc func interceptedDelegate(delegate : CLLocationManagerDelegate) {
        locationDeleage = delegate
        self.interceptedDelegate(delegate: self)
    }
    
    static func swizzle() {
        let _: () = {
            let originalSelector = #selector(setter: CLLocationManager.delegate)
            let swizzledSelector = #selector(CLLocationManager.interceptedDelegate(delegate:))
            let originalMethod = class_getInstanceMethod(self, originalSelector)
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            method_exchangeImplementations (originalMethod!, swizzledMethod!)
        }()
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("swizzle -- locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation])")
        locationDeleage?.locationManager!(manager, didUpdateLocations: locations)
    }
}
