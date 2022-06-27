//
//  QRCodeElements.swift
//  FantasmoSDKUITests
//
//  Created by Fantasmo QA on 11/5/2022.
//

import XCTest

enum QRCodeElements {
    private static let app = XCUIApplication()
    
    static func torchButton() -> XCUIElement {
        return app.buttons["Torch"]
    }
    
    static func enterCodeButton() -> XCUIElement {
        return app.buttons["Enter Code"]
    }
    
    static func enterQRCodeField() -> XCUIElement {
        return app.alerts["Enter QR Code"].textFields.firstMatch
    }
    
    static func submitQRCodeButton() -> XCUIElement {
        return app.buttons["Submit"]
    }
}
