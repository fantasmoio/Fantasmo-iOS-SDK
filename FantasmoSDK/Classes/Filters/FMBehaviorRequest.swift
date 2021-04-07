//
//  FMBehaviorDirector.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 4/1/21.
//

import Foundation

public enum FMBehaviorRequest: String {
    case tiltUp = "Tilt your device up"
    case tiltDown = "Tilt your device down"
    case panAround = "Pan around the scene"
    case panSlowly = "Pan more slowly"
}

/// maps filter FMRemedy to a remedial user behavior
extension FMBehaviorRequest {
    init(_ remedy : FMRemedy) {
        switch remedy {
        case .tiltUp:
            self = .tiltUp
        case .tiltDown:
            self = .tiltDown
        case .slowDown:
            self = .panSlowly
        case .panAround:
            self = .panAround
        }
    }
}
