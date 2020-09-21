//
//  ARSessionManager.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import UIKit
import ARKit

private var arSessionDelegate: ARSessionDelegate?
private var state = State.idle
private let detector = CIDetector(ofType: CIDetectorTypeQRCode,
                          context: nil,
                          options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])!
private var qrFramePose = TOSPose()
private var arSession: ARSession!

enum State {
    case idle
    case checkingForQRCode
    case validatedQRCode
    case capturingImage
    case localizing
    case validated
}

extension ARSession : ARSessionDelegate {
    @objc func interceptedDelegate(delegate : ARSessionDelegate) {
        arSessionDelegate = delegate
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
        print("swizzle -- ARSession did Update frame")
        arSession = session
        if (state == .idle) {
            checkFrameForQrCode(frame)
        } else if (state == .capturingImage) {
            let pitch = frame.camera.eulerAngles[0]
            if (pitch >= -0.05) && (pitch < 0.5) {
                self.localize()
            }
        }
        arSessionDelegate?.session?(session, didUpdate: frame)
    }
    
    private func localize() {
        guard let frame = arSession?.currentFrame else {
            print("No current frame available for localization.")
            return
        }
        state = .localizing
                        
        // Get the UI orientations on the main thread so they can be
        // used in the background thread
        let statusBarOrientation = UIApplication.shared.statusBarOrientation
        let deviceOrientation = UIDevice.current.orientation
        
        // Query the server with the current frame
        DispatchQueue.global(qos: .background).async {
            let tosImage = TOSImage(frame: frame,
                                 withStatusBarOrientation: statusBarOrientation,
                                 withDeviceOrientation: deviceOrientation,
                                 atLocation: nil)
            
            guard let jpegData = TOSImage.convertToJpeg(fromPixelBuffer: frame.capturedImage,
                                                        withDeviceOrientation: deviceOrientation) else {
                                                            print("Error: Could not convert frame to JPEG.")
                                                            return
            }
        
            let intrinsicsJson = String(format: "{\"fx\": %f, \"fy\": %f, \"cx\": %f, \"cy\": %f}",
                                        tosImage.intrinsics.fx,
                                        tosImage.intrinsics.fy,
                                        tosImage.intrinsics.cx,
                                        tosImage.intrinsics.cy)
            
            let gravityJson = String(format: "{\"w\": %f, \"x\": %f, \"y\": %f, \"z\": %f}",
                                     tosImage.pose.orientation.w,
                                     tosImage.pose.orientation.x,
                                     tosImage.pose.orientation.y,
                                     tosImage.pose.orientation.z)
            
            let parameters = [
                "intrinsics" : intrinsicsJson,
                "gravity"    : gravityJson
            ]

            NetworkManager.uploadImage(url: Server.Constants.routeUrl, parameters: parameters, image: tosImage, jpegData: jpegData, mapName: "", onCompletion: { (response) in
                if let response = response {
                    print(response)
                }
            }) { (error) in
                print(error?.localizedDescription ?? "")
            }
        }
    }
    
    private func checkFrameForQrCode(_ frame: ARFrame) {
        
        state = .checkingForQRCode
        
        DispatchQueue.global(qos: .utility).async {
            let image = CIImage(cvPixelBuffer: frame.capturedImage)
            
            if let feature = detector.features(in: image).first as? CIQRCodeFeature {
                
                DispatchQueue.main.async {
                    self.processQrCodeFeature(feature, forFrame: frame)
                }
            } else {
                state = .idle
            }
        }
    }
    
     private func processQrCodeFeature(_ qrCodeFeature: CIQRCodeFeature, forFrame frame:ARFrame) {
        
        print(frame.camera.imageResolution)
        qrFramePose = TOSPose(fromTransform: frame.camera.transform)
        state = .validatedQRCode
        
        if #available(iOS 11.3, *) {
            if let currentSessionConfiguration = arSession.configuration as? ARWorldTrackingConfiguration {
                print("Turning auto focus OFF")
                currentSessionConfiguration.isAutoFocusEnabled = true
                arSession.run(currentSessionConfiguration)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            state = .capturingImage
        }
    }
}
