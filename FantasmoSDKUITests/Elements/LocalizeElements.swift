//
//  LocalizeElements.swift
//  FantasmoSDKUITests
//
//  Created by Fantasmo QA on 28/4/2022.
//

import XCTest

enum LocalizeSwitch: String, CaseIterable {
    case qrCode = "tog_scanQRCode"
    case debugStats = "tog_debugStatistics"
    case simulationMode = "tog_simulationMode"
}

enum LocalizeElements {
    private static let app = XCUIApplication()
    
    static func getSwitch(_ toggle: LocalizeSwitch) -> XCUIElement {
        return app.switches[toggle.rawValue]
    }
    
    static func localizeButton() -> XCUIElement {
        return app.buttons["btn_localize"]
    }
    
    static func localizeResults() -> XCUIElement {
        return app.staticTexts["txt_localizeResults"]
    }
}
