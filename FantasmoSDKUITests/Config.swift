//
//  Config.swift
//  FantasmoSDKUITests
//
//  Created by Fantasmo QA on 28/4/2022.
//

import XCTest

public let AUTName = "Test Harness Dev"

public struct UITestTimeout {
    static var element: TimeInterval = 5.0
    static var request: TimeInterval = 45.0
}

// Better booleans/state descriptors for switches and toggles
public enum SwitchState {
    case On
    case Off
}

public enum ToggleState {
    case On
    case Off
}

public enum TorchState {
    case On
    case Off
}
