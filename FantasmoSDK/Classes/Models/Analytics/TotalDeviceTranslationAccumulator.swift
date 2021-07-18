//
//  ARKitDeviceMotion.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 14.07.2021.
//

import ARKit

/// Calculates the trajectory length of a device based on the device transform provided by the sequence of ARKit frames.
///
/// To reduce error introduced by noise we use decimation (downsampling without passing through low-pass filter) by an integer factor as the most
/// simple approach which should yield sufficient accuracy.
/// More info about downsampling and decimation can be read at https://en.wikipedia.org/wiki/Downsampling_(signal_processing)
struct TotalDeviceTranslationAccumulator {
    
    /// Current value of total translation, which is updated as more frames are received.
    private(set) var totalTranslation: Float = 0.0
    
    /// Number of each frame in a frame sequence which should be taken for calculating total device translation.
    private(set) var decimationFactor: UInt = 10
    
    private var frameCounter: UInt = 0
    private var nextFrameToTake: UInt = 0
    private var previousTranslation: simd_float3!
    
    init(decimationFactor: UInt = 10) {
        self.decimationFactor = decimationFactor
    }
    
    mutating func update(forNextFrame frame: ARFrame) {
        if previousTranslation == nil {
            previousTranslation = frame.camera.transform.translation
        }
        
        if frameCounter == nextFrameToTake {
            if case .normal = frame.camera.trackingState {
                let translation = frame.camera.transform.translation
                totalTranslation += distance(translation, previousTranslation ?? translation)
                previousTranslation = translation
                nextFrameToTake += decimationFactor
            }
            else {
                nextFrameToTake += 1
            }
        }
        
        frameCounter += 1
    }
    
    mutating func reset() {
        frameCounter = 0
        nextFrameToTake = 0
        previousTranslation = nil
        totalTranslation = 0.0
    }
    
}
