//
//  ARSessionManager.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import UIKit
import ARKit

private var sessionDelegate: ARSessionDelegate?
private var sessionObj: ARSession!


extension ARSession : ARSessionDelegate {
    @objc func interceptedDelegate(delegate : ARSessionDelegate) {
        sessionDelegate = delegate
        self.interceptedDelegate(delegate: self)
    }
    
    static func swizzle() {
        let _: () = {
            let originalSelector = #selector(setter: ARSession.delegate)
            let swizzledSelector = #selector(ARSession.interceptedDelegate(delegate:))
            let originalMethod = class_getInstanceMethod(self, originalSelector)
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            method_exchangeImplementations (originalMethod!, swizzledMethod!)
        }()
    }
    
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        print("didUpdate frame Called")
        sessionObj = session
        let pitch = frame.camera.eulerAngles[0]
        if (pitch >= -0.05) && (pitch < 0.5) {
            FMLocationManager.shared.localize(frame: frame)
        }
        sessionDelegate?.session?(session, didUpdate: frame)
    }
}
