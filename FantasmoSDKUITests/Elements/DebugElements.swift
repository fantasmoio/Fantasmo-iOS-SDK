//
//  DebugElements.swift
//  FantasmoSDKUITests
//
//  Created by Fantasmo QA on 2/5/2022.
//

import XCTest

enum DebugTextField: String, CaseIterable {
    case sdkVersion = "txt_sdkVersion"
    case localizationStatus = "txt_localizationStatus"
    case framesCurrentWindow = "txt_currentWindow"
    case framesEvaluated = "txt_framesEvaluated"
    case framesRejected = "txt_framesRejected"
    case bestScore = "txt_bestScore"
    case liveScore = "txt_liveScore"
    case lastError = "txt_lastError"
    case modelVersion = "txt_modelVersion"
    case lastResult = "txt_lastResult"
    case errorCount = "txt_errorCount"
    case deviceLocation = "txt_deviceLocation"
    case translation = "txt_translation"
    case totalTranslation = "txt_totalTranslation"
    case remoteConfigID = "txt_remoteConfigID"
    case eulerAngles = "txt_eulerAngles"
    case eulerAngleSpreads = "txt_eulerAngleSpreads"
    case totalFrameRejections = "txt_totalFrameRejections"
}

enum DebugElements {
    private static let app = XCUIApplication()

    static func textField(_ field: DebugTextField) -> XCUIElement {
        return app.staticTexts[field.rawValue]
    }
}
