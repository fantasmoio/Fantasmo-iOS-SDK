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
public class TotalDeviceTranslationAccumulator {
    
    /// Current value of total translation in meters, which is updated as more frames are passed via `update(`
    private(set) var totalTranslation: Float = 0.0 {
        didSet {
            totalTranslationObservers.forEach { _, closure in
                closure(totalTranslation)
            }
        }
    }
    
    /// Number of each frame in a frame sequence which should be taken for calculating total device translation.
    private(set) var decimationFactor: UInt = 10
    
    private var frameCounter: UInt = 0
    private var nextFrameToTake: UInt = 0
    private var previousTranslation: simd_float3!
    private var totalTranslationObservers = [UUID : ((Float) -> Void)]()
    
    public init(decimationFactor: UInt = 10) {
        self.decimationFactor = decimationFactor
    }

    func update(with nextFrame: ARFrame) {
        if previousTranslation == nil {
            previousTranslation = nextFrame.camera.transform.translation
        }
        
        if frameCounter == nextFrameToTake {
            if case .normal = nextFrame.camera.trackingState {
                let translation = nextFrame.camera.transform.translation
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
    
    func reset() {
        frameCounter = 0
        nextFrameToTake = 0
        previousTranslation = nil
        totalTranslation = 0.0
    }
    
}

extension TotalDeviceTranslationAccumulator {
    public func observeTotalTranslation(using closure: @escaping (Float) -> Void) -> ObservationToken {
        let id = totalTranslationObservers.insert(closure)
        return ObservationToken { [weak self] in
            self?.totalTranslationObservers.removeValue(forKey: id)
        }
    }
}
