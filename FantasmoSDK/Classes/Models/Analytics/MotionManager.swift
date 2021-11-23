//
//  MotionManager.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 8/6/21.
//

import Foundation
import CoreMotion

/// Encapsulates device motion updates used for getting magnetometer data
/// If no data is gathered, an all-zero field is return
class MotionManager {
    lazy private var motionManager: CMMotionManager = {
        let motionManager = CMMotionManager()
        motionManager.deviceMotionUpdateInterval = 1.0/15.0
        return motionManager
    }()
    private(set) var magneticField: MagneticField?

    struct MagneticField: Codable {
        var x = 0.0
        var y = 0.0
        var z = 0.0
    }

    func restart() {
        magneticField = nil
        motionManager.startDeviceMotionUpdates(
            using: CMAttitudeReferenceFrame.xArbitraryCorrectedZVertical,
            to: .main) { (motion, error) in
            if let field = motion?.magneticField.field {
                self.magneticField = MagneticField(x: field.x, y: field.y, z: field.z)
            }
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}
