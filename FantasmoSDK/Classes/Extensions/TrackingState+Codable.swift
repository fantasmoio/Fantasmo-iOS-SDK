//
//  TrackingState+Codable.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 02.06.22.
//

import ARKit

extension ARCamera.TrackingState: Codable, Equatable, CustomStringConvertible {
    
    public var description: String {
        switch self {
        case .normal:
            return "normal"
        case let .limited(reason):
            return "limited, \(reason)"
        default:
            return "not available"
        }
    }
    
    public static var codableCases: [ARCamera.TrackingState] {
        var cases: [ARCamera.TrackingState] = [.notAvailable, .normal, .limited(.initializing), .limited(.excessiveMotion), .limited(.insufficientFeatures)]
        if #available(iOS 11.3, *) {
            cases.append(.limited(.relocalizing))
        }
        return cases
    }
    
    public static func == (lhs: ARCamera.TrackingState, rhs: ARCamera.TrackingState) -> Bool {
        switch (lhs, rhs) {
        case (.notAvailable, .notAvailable):
            return true
        case (.normal, .normal):
            return true
        case (let .limited(reasonLeft), let .limited(reasonRight)):
            return reasonLeft == reasonRight
        default:
            return false
        }
    }
        
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        let caseIndex = ARCamera.TrackingState.codableCases.firstIndex(of: self)
        try container.encode(caseIndex ?? 0)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let caseIndex = try container.decode(Int.self)
        self = ARCamera.TrackingState.codableCases[caseIndex]
    }
}
