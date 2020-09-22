//
//  FMIntrinsics.swift
//  FantasmoSDK
//
//  Copyright © 2020 Fantasmo. All rights reserved.
//

import ARKit

public struct FMIntrinsics:Codable {
    
    var fx:Float
    var fy:Float
    var cx:Float
    var cy:Float
    var radialDistortion:[Float]?
    var tangentialDistortion:[Float]?
    
    init(fromIntrinsics intrinsics: simd_float3x3,
         atScale scale:Float,
         withStatusBarOrientation statusBarOrientation:UIInterfaceOrientation,
         withDeviceOrientation deviceOrientation:UIDeviceOrientation,
         withFrameWidth frameWidth: Int,
         withFrameHeight frameHeight: Int) {
        
        switch deviceOrientation {
            
        case .landscapeLeft:
            fx = intrinsics.columns.0.x
            fy = intrinsics.columns.1.y
            cx = intrinsics.columns.2.x
            cy = intrinsics.columns.2.y
            break
            
        case .landscapeRight:
            fx = intrinsics.columns.0.x
            fy = intrinsics.columns.1.y
            cx = Float(frameWidth) - intrinsics.columns.2.x
            cy = Float(frameHeight) - intrinsics.columns.2.y
            break
            
        case .portrait:
            fx = intrinsics.columns.1.y
            fy = intrinsics.columns.0.x
            cx = intrinsics.columns.2.y
            cy = intrinsics.columns.2.x
            break
            
        case .portraitUpsideDown:
            fx = intrinsics.columns.1.y
            fy = intrinsics.columns.0.x
            cx = Float(frameHeight) - intrinsics.columns.2.y
            cy = Float(frameWidth) - intrinsics.columns.2.x
            break
        default:
            fx = intrinsics.columns.1.y
            fy = intrinsics.columns.0.x
            cx = intrinsics.columns.2.y
            cy = intrinsics.columns.2.x
            break
        }
        
        fx *= Float(scale)
        fy *= Float(scale)
        cx *= Float(scale)
        cy *= Float(scale)
    }
}
