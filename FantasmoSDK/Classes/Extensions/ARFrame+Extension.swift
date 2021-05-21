//
//  ARFrame+Extension.swift
//  Fantasmo-iOS-SDK-Test-Harness
//
//  Created by lucas kuzma on 3/18/21.
//

import ARKit

public extension ARFrame {
    
    /// In OpenCV conventions coordinate system is turned by 180˚ about X-axis or the original coordinate system.
    @inline(__always) private static let transformForOpenCVConventions =
        simd_float4x4( simd_quatf(angle: .pi, axis: SIMD3(x: 1, y: 0, z: 0)) )
    
    /// Transform of the device in the coordinate system of camera.
    /// For camera CS the X-axis always points along the long axis of the device (from the front camera toward the Home, https://apple.co/3t1Dw33)
    /// For device coordinate system the Y-axis always points along the long axis of the device toward the front camera - https://apple.co/2R37LJW.
    @inline(__always) private static let transformOfDeviceInCameraCS = simd_float4x4(
        simd_quatf(angle: .pi/2, axis: SIMD3(x: 0, y: 0, z: 1))
    )
    
    /// Transform of the OpenCV device in the coordinate system of camera.
    /// For details about orientation of the coordinate systems see comment to `ARFrame.transformOfOpenCVDeviceInOpenCVWorldCS`
    @inline(__always) private static let transformOfOpenCVDeviceInCameraCS =
        ARFrame.transformOfDeviceInCameraCS * transformForOpenCVConventions
    
    @inline(__always) var transformOfDeviceInWorldCS: simd_float4x4 {
        camera.transform * ARFrame.transformOfDeviceInCameraCS
    }
    
    /// The transform of the OpenCV device  in the OpenCV world coordinate space.
    /// For camera coordinate system (CS) the X-axis always points along the long axis of the device (from the front-facing camera toward the Home)
    /// For device coordinate system the Y-axis always points along the long axis of the device toward the front camera - https://apple.co/2R37LJW.
    /// For "OpenCV device" CS of device is turned through `pi` about x axis of device CS - https://bit.ly/3aDghGe, so Y-axis points from the
    /// front camera toward the Home button.
    /// OpenCV World coordinate system is turned through 180˚ about X-axis of the World CS. It is right-handed with Y-axis directed down and aligned
    /// with gravity.
    @inline(__always) var transformOfOpenCVDeviceInOpenCVWorldCS: simd_float4x4 {
        return ARFrame.transformForOpenCVConventions * camera.transform * ARFrame.transformOfOpenCVDeviceInCameraCS
    }
    
    /// Returns transform of a OpenCV virtual device in the "OpenCV world coordinate system".
    /// Y-axis of the OpenCV virtual device always  approximately coincides with y-axis of the OpenCV world coordinate system and
    /// is always turned about Z-axis of the OpenCV device coordinate system (https://apple.co/2R37LJW) through angle that is multiple of 90°.
    /// For details about orientation of the coordinate systems see comment to `ARFrame.transformOfOpenCVDeviceInOpenCVWorldCS`
    @inline(__always) func transformOfOpenCvVirtualDeviceInOpenCVWorldCS(
        for deviceOrientation: UIDeviceOrientation
    ) -> simd_float4x4 {
        /// Do not confuse "virtual device" with "OpenCV virtual device", they are rotated relative to each other through `.pi` about x-axis.
        let angleOfVirtualDeviceCSRelativeToCameraCS: Float
        
        switch deviceOrientation {
        case .portrait:
            angleOfVirtualDeviceCSRelativeToCameraCS = .pi/2
        case .portraitUpsideDown:
            angleOfVirtualDeviceCSRelativeToCameraCS = -.pi/2
        case .landscapeLeft:
            angleOfVirtualDeviceCSRelativeToCameraCS = 0
        case .landscapeRight:
            angleOfVirtualDeviceCSRelativeToCameraCS = .pi
        default:
            angleOfVirtualDeviceCSRelativeToCameraCS = .pi/2
        }
        
        let quaternionOfVirtualDeviceCSInCameraCS =
            simd_quatf(angle: angleOfVirtualDeviceCSRelativeToCameraCS, axis: SIMD3(x:0, y: 0, z: 1))
        let quaternionOfOpenCvVirtualDeviceInVirtualDeviceCS = simd_quatf(angle: .pi, axis: SIMD3(x: 1, y: 0, z: 0))
        
        let quaternionOfOpenCvVirtualDeviceInCameraCS =
            quaternionOfVirtualDeviceCSInCameraCS * quaternionOfOpenCvVirtualDeviceInVirtualDeviceCS
        let transformOfOpenCvVirtualDeviceCSInCameraCS = simd_float4x4(quaternionOfOpenCvVirtualDeviceInCameraCS)
        
        return ARFrame.transformForOpenCVConventions * camera.transform * transformOfOpenCvVirtualDeviceCSInCameraCS
    }

    /// Returns device orientation based on orientation of camera at the moment of capturing the frame.
    /// Function works only if `ARSession.configuration.worldAlignment != .camera`, otherwise it returns `.unknown`
    /// Using `UIDevice` for this purpose is not desirable as client of SDK can use it and disable delivering of orientation events invoking
    /// `UIDevice.endGeneratingDeviceOrientationNotifications()`, which would cause problems for proper functioning of SDK.
    /// - Note: property is
    func deviceOrientation(session: ARSession) -> UIDeviceOrientation {
        if session.configuration?.worldAlignment != .camera {
            let pitch = camera.eulerAngles.x
            let roll = camera.eulerAngles.z
            
            if abs(pitch) < .pi/4 {
                switch roll {
                case -3.0/4 * .pi ..< -1.0/4 * .pi:
                    return .portrait
                case -1.0/4 * .pi ..< 1.0/4 * .pi:
                    return .landscapeLeft
                case 1.0/4 * .pi ..< 3.0/4 * .pi:
                    return .portraitUpsideDown
                case (3.0/4 * .pi)...:
                    return .landscapeRight
                case ..<(-3.0/4 * .pi):
                    return .landscapeRight
                default:
                    assertionFailure("Improper logic!")
                    return .unknown
                }
            } else if pitch <= -.pi/4 {
                return .faceUp
            } else if pitch >= -.pi/4 {
                return .faceDown
            } else {
                assertionFailure("Improper logic!")
                return .unknown
            }
        } else {
            return .unknown
        }
    }
    
}
