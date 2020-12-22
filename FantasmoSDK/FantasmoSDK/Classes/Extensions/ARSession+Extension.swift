//
//  FMSwizzleExtension.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import UIKit
import ARKit
import CoreLocation
import CocoaLumberjack
#if SWIFT_PACKAGE
import CocoaLumberjackSwift
#endif

extension ARSession : ARSessionDelegate {
    
    private struct AssociatedKeys {
        static var delegateState: UInt8 = 0
    }
    
    public private(set) static var lastFrame: ARFrame?
    
    /**
     Intercept delegate method for execute delegate.
     
     - Parameter delegate: Delegate of ARSession .
     */
    @objc func interceptedDelegate(delegate : Any) {
        objc_setAssociatedObject(self, &AssociatedKeys.delegateState, delegate, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        self.interceptedDelegate(delegate: self)
    }
    
    /**
     Swizzle method for exchange swizzled and original methods
     */
    static func swizzle() {
        let _: () = {
            let originalSelector = #selector(setter: ARSession.delegate)
            let swizzledSelector = #selector(ARSession.interceptedDelegate(delegate:))
            let originalMethod = class_getInstanceMethod(self, originalSelector)
            let swizzledMethod = class_getInstanceMethod(self, swizzledSelector)
            method_exchangeImplementations (originalMethod!, swizzledMethod!)
            DDLogVerbose("ARSession:swizzle")
        }()
    }
    
    /**
     This is called when a new frame has been updated.
     
     @param session The session being run.
     @param frame The frame that has been updated.
     */
    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
        ARSession.lastFrame = frame
        
        //let pitch = frame.camera.eulerAngles[0]
 
        if FMLocationManager.shared.state == .idle {
            DDLogWarn("ARSession:swizzle didUpdate frame localize called")
            FMLocationManager.shared.localize(frame: frame)
        }
            
        guard let delegate = objc_getAssociatedObject(self, &AssociatedKeys.delegateState) as? ARSessionDelegate else {
            DDLogWarn("ARSession:swizzle didUpdate frame delegate not available")
            return
        }
        
        delegate.session?(session, didUpdate: frame)
        //DDLogVerbose("ARSession:swizzle didUpdate frame")
    }
}


