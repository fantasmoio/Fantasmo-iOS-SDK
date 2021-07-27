//
//  EulerAngleSpreads.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 27.07.2021.
//

import Foundation

public struct EulerAngleSpreads: Encodable {
    /// The magnitude of range in which changes were observed for pitch. Valid interval is [0, pi]
    public let pitchSpread: Float
    
    /// The magnitude of range in which changes were observed for way. Valid interval is [0, 2pi]
    public let yawSpread: Float
    
    /// The magnitude of range in which changes were observed for roll. Valid interval is [0, 2pi]
    public let rollSpread: Float
    
    enum CodingKeys: String, CodingKey {
        case pitchSpread =  "pitch"
        case yawSpread = "yaw"
        case rollSpread = "roll"
    }
    
    init(pitchSpread: Float, yawSpread: Float, rollSpread: Float) {
        precondition(0.0...(.pi) ~= pitchSpread, "Invalid `pitchSpread`: \(pitchSpread)")
        precondition(0.0...(.two_pi) ~= pitchSpread, "Invalid `yawSpread`: \(yawSpread)")
        precondition(0.0...(.two_pi) ~= pitchSpread, "Invalid `rollSpread`: \(rollSpread)")
        
        self.pitchSpread = pitchSpread
        self.yawSpread = yawSpread
        self.rollSpread = rollSpread
    }
}
