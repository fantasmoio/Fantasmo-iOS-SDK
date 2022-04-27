//
//  DebugQuestions.swift
//  FantasmoSDKUITests
//
//  Created by Fantasmo QA on 10/5/2022.
//

import XCTest
import AVFoundation
import FantasmoSDK

enum Debug: Question {
    case text(_ actual: String, _ expected: String)
    case torch(_ actual: TorchState, _ expected: TorchState)
    
    func ask() {
        switch self {
        case .text(let actualValue, let expectedValue):
            XCTAssertEqual(actualValue, expectedValue)
        case .torch(let actualValue, let expectedValue):
            XCTAssertEqual(actualValue, expectedValue)
        }
    }
    
    private static func getTorchState() -> TorchState {
        // return off if the device has no AVCapture default device
        guard let device = AVCaptureDevice.default(for: .video) else { return TorchState.Off }

        if device.hasTorch && (device.torchMode == AVCaptureDevice.TorchMode.on || device.isTorchActive) {
            return TorchState.On
        }

        // if no torch present or torchMode is in any other state we return off
        return TorchState.Off
    }
    
    static func DebugContent(of textField: DebugTextField, is expectedValue: String) -> Debug {
        let actualValue = DebugElements.textField(textField).label
        return text(actualValue, expectedValue)
    }
    
    static func Torch(is expectedValue: TorchState) -> Debug {
        let actualValue = getTorchState()
        return torch(actualValue, expectedValue)
    }
}
