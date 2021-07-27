//
//  ARCamera.TrackingState+Extension.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 27.07.2021.
//

import ARKit

extension ARCamera.TrackingState: Hashable {
    
    public static func == (lhs: ARCamera.TrackingState, rhs: ARCamera.TrackingState) -> Bool {
        if case .normal = lhs, case .normal = rhs {
            return true
        }
        else if case .limited(let lhsReason) = lhs, case .limited(let rhsReason) = rhs, lhsReason == rhsReason {
            return true
        }
        else if case .notAvailable = lhs, case .notAvailable = rhs {
            return true
        }
        else {
            return false
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .normal:
            hasher.combine(1)
        case .limited(let reason):
            switch reason {
            case .initializing:
                hasher.combine(11)
            case .relocalizing:
                hasher.combine(12)
            case .excessiveMotion:
                hasher.combine(13)
            case .insufficientFeatures:
                hasher.combine(14)
            @unknown default:
                fatalError("Unknown reason for `limited` case \(reason)")
            }
        case .notAvailable:
            hasher.combine(3)
        }
    }
}
