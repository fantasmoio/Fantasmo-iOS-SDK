//
//  ARFrame+Extension.swift
//  Fantasmo-iOS-SDK-Test-Harness
//
//  Created by lucas kuzma on 3/18/21.
//

import ARKit


extension ARFrame: FMFrame {
    var fmCamera: FMCamera {
        return self.camera
    }
    
    /// OpenCV coordinate system is turned by 180˚ about X-axis relative to the original coordinate system.
    private static let transformOfOpenCVCoordinateSystem = simd_float4x4.rotationAboutXAxisByPiRad
    
    /// Transform of the device in the coordinate system of camera.
    /// For camera CS the X-axis always points along the long axis of the device (from the front camera toward the Home, https://apple.co/3t1Dw33)
    /// For device coordinate system the Y-axis always points along the long axis of the device toward the front camera - https://apple.co/2R37LJW.
    private static let transformOfDeviceInCameraCS = simd_float4x4(
        simd_quatf(angle: .pi/2, axis: SIMD3(x: 0, y: 0, z: 1))
    )

    /// Transform of the OpenCV device in the coordinate system of camera.
    /// For details about orientation of the coordinate systems see comment to `ARFrame.openCVTransformOfDeviceInWorldCS`
    private static let transformOfOpenCVDeviceInCameraCS =
        ARFrame.transformOfDeviceInCameraCS * transformOfOpenCVCoordinateSystem
    
    /// For camera CS the X-axis always points along the long axis of the device (from the front camera toward the Home, https://apple.co/3t1Dw33)
    /// For device coordinate system the Y-axis always points along the long axis of the device toward the front camera - https://apple.co/2R37LJW.
    public var transformOfDeviceInWorldCS: simd_float4x4 {
        camera.transform * ARFrame.transformOfDeviceInCameraCS
    }
    
    /// Y-axis of the virtual device always  approximately coincides with y-axis of the world coordinate system (that is approximately vertical) and
    /// is always turned about Z-axis of the device coordinate system (https://apple.co/2R37LJW) through multiple of 90°.
    /// For example, if device is turned by more than 45° about Z-axis then CS of virtual device is turned by -45° about Z-axis so that its Y-axis is near to
    ///     vertical direction.
    /// For details about orientation of the coordinate systems see comment to `ARFrame.transformOfDeviceInWorldCS`
    public var transformOfVirtualDeviceInWorldCS: simd_float4x4 {
        let angleOfVirtualDeviceCSInCameraCS = self.angleOfVirtualDeviceCSInCameraCS(deviceOrientation)
        
        let quaternionOfVirtualDeviceCSInCameraCS =
            simd_quatf(angle: angleOfVirtualDeviceCSInCameraCS, axis: SIMD3(x:0, y: 0, z: 1))

        let transformOfVirtualDeviceCSInCameraCS = simd_float4x4(quaternionOfVirtualDeviceCSInCameraCS)
        
        return camera.transform * transformOfVirtualDeviceCSInCameraCS
    }
    
    /// The transform of the OpenCV device  in the OpenCV world coordinate space.
    /// For camera coordinate system (CS) the X-axis always points along the long axis of the device (from the front-facing camera toward the Home)
    /// For device coordinate system the Y-axis always points along the long axis of the device toward the front camera - https://apple.co/2R37LJW.
    /// For "OpenCV device" CS of device is turned through `pi` about x axis of device CS - https://bit.ly/3aDghGe, so Y-axis points from the
    /// front camera toward the Home button.
    /// OpenCV World coordinate system is turned through 180˚ about X-axis of the World CS. It is right-handed with Y-axis directed down and aligned
    /// with gravity.
    /// - Note: result of calculating of `deviceOrientation` is cached, so subsequent invocations of this calculated property are cheap.
    var openCVTransformOfDeviceInWorldCS: simd_float4x4 {
        if let transform: simd_float4x4 =
            getAssociatedObject(object: self, associativeKey: &AssociatedKey.openCVTransformOfDeviceInWorldCS) {
            return transform
        }
        else {
            let transform = camera.transform.inOpenCvCS * ARFrame.transformOfOpenCVDeviceInCameraCS
            setAssociatedObject(object: self,
                                value: transform,
                                associativeKey: &AssociatedKey.openCVTransformOfDeviceInWorldCS,
                                policy: objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return transform
        }
    }
    
    /// Returns transform of a OpenCV virtual device in the "OpenCV world coordinate system".
    /// Y-axis of the OpenCV virtual device always  approximately coincides with y-axis of the OpenCV world coordinate system and
    /// is always turned about Z-axis of the OpenCV device coordinate system (https://apple.co/2R37LJW) through multiple of 90°.
    /// For details about orientation of the coordinate systems see comment to `ARFrame.openCVTransformOfDeviceInWorldCS`
    var openCVTransformOfVirtualDeviceInWorldCS: simd_float4x4 {
        if let transform: simd_float4x4 =
            getAssociatedObject(object: self, associativeKey: &AssociatedKey.openCVTransformOfVirtualDeviceInWorldCS) {
            return transform
        }
        else {
            let transform =
                transformOfVirtualDeviceInWorldCS.inOpenCvCS * ARFrame.transformOfOpenCVCoordinateSystem
            setAssociatedObject(object: self,
                                value: transform,
                                associativeKey: &AssociatedKey.openCVTransformOfVirtualDeviceInWorldCS,
                                policy: objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return transform
        }
    }
    
    /// Angle in radians.
    private func angleOfVirtualDeviceCSInCameraCS(
        _ deviceOrientation: UIDeviceOrientation
    ) -> Float {
        switch deviceOrientation {
        case .portrait:
            return .pi/2
        case .portraitUpsideDown:
            return -.pi/2
        case .landscapeLeft:
            return 0
        case .landscapeRight:
            return .pi
        default:
            return .pi/2
        }
    }

    /// Returns device orientation based on orientation of camera at the moment of capturing the frame.
    /// Using `UIDevice` for this purpose is not desirable as client of SDK can use it and disable delivering of orientation events invoking
    /// `UIDevice.endGeneratingDeviceOrientationNotifications()`, which would cause problems for proper functioning of SDK.
    /// - Note: result of calculating of `deviceOrientation` is cached, so subsequent invocations of this calculated property are cheap.
    /// - WARNING: function works only if `ARSession.configuration.worldAlignment != .camera`, otherwise it returns `.portrait`
    public var deviceOrientation: UIDeviceOrientation {
        if let cachedDeviceOrientation: UIDeviceOrientation =
            getAssociatedObject(object: self, associativeKey: &AssociatedKey.deviceOrientation) {
            return cachedDeviceOrientation
        }
        else {
            let pitch = camera.eulerAngles.x
            let roll = camera.eulerAngles.z
            
            let orientation: UIDeviceOrientation
            
            if abs(pitch) < .pi/4 {
                switch roll {
                case -3.0/4 * .pi ..< -1.0/4 * .pi:
                    orientation = .portrait
                case -1.0/4 * .pi ..< 1.0/4 * .pi:
                    orientation = .landscapeLeft
                case 1.0/4 * .pi ..< 3.0/4 * .pi:
                    orientation = .portraitUpsideDown
                case (3.0/4 * .pi)...:
                    orientation = .landscapeRight
                case ..<(-3.0/4 * .pi):
                    orientation = .landscapeRight
                default:
                    orientation = .unknown
                }
            } else if pitch <= -.pi/4 {
                orientation = .faceUp
            } else if pitch >= -.pi/4 {
                orientation = .faceDown
            } else {
                orientation = .unknown
            }
            
            setAssociatedObject(object: self,
                                value: orientation,
                                associativeKey: &AssociatedKey.deviceOrientation,
                                policy: objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return orientation
        }
    }
    
    private struct AssociatedKey {
        static var openCVTransformOfDeviceInWorldCS = "openCVTransformOfDeviceInWorldCS"
        static var openCVTransformOfVirtualDeviceInWorldCS = "openCVTransformOfVirtualDeviceInWorldCS"
        static var deviceOrientation = "deviceOrientation"
    }
    
}
