//
//  Angle.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 30.04.2021.
//

import Foundation

// Represents the degree of turn between two straight lines with a common vertex.
public struct Angle: CustomStringConvertible, Equatable {
    
    /// The pi constant, the ratio of a circle's circumference to its diameter
    public static let (pi, π) = (Double.pi, Double.pi)
    
    /// The tau constant, the ratio of a circle's circumference to its radius
    public static let (tau, τ)  = (2 * pi, 2 * pi)
    
    /// The default constructor creates a zero angle
    public init() { _radians = 0 }
    
    /// Initializes with radians
    public init(radians: Double) { _radians = radians }
    
    /// Initializes with user-supplied degrees
    public init(degrees: Double) { _radians = degrees * Angle.pi / 180.0 }
    
    /// Initializes with user-supplied count of π's
    public init(multiplesOfPi piCount: Double) { _radians = piCount * Angle.pi }
    
    /// Initializes with user-supplied count of τ's
    public init(multiplesOfTau tauCount: Double) { _radians = tauCount * Angle.pi }

    /// Expresses angle in degrees
    public var degrees: Double { return _radians * 180.0 / Angle.pi }
    
    /// Expresses angles as a count of pi
    public var multiplesOfPi: Double { return _radians / Angle.pi }
    
    /// Expresses angles as a count of tau
    public var multiplesOfTau: Double { return _radians / Angle.tau }

    /// Expresses angle in (native) radians
    public var radians: Double { return _radians }
    
    /// String convertible support
    public var description: String {
        return "\(degrees)°, \(multiplesOfPi)π, \(radians) rads"
    }
    
    /// Compares two angles, conforming type to `Equatable`
    public static func ==(lhs: Angle, rhs: Angle) -> Bool {
        return lhs.radians == rhs.radians
    }
    
    /// Internal radian store
    private let _radians: Double
}


// MARK: - Global functions

public func rad2deg<T: FloatingPoint>(_ number: T) -> T {
    return number * 180 / .pi
}
