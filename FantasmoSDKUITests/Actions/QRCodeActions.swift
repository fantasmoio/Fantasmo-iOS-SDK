//
//  QRCodeActions.swift
//  FantasmoSDKUITests
//
//  Created by Fantasmo QA on 11/5/2022.
//

import XCTest

// these elements can be on screen but return false for "isHittable"
// which is why we force tap them based on a coordinate
enum QRCodeActions {
    static func tapTorchButton() {
        QRCodeElements.torchButton().forceTapElement()
    }
    
    static func tapEnterCodeButton() {
        QRCodeElements.enterCodeButton().forceTapElement()
    }
    
    static func enterCode(_ text: String) {
        QRCodeElements.enterQRCodeField().typeText(text)
    }
    
    static func submitCode() {
        QRCodeElements.submitQRCodeButton().tapWhenHittable()
    }
}
