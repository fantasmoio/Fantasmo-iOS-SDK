//
//  PermissionsElements.swift
//  FantasmoSDKUITests
//
//  Created by Fantasmo QA on 27/4/2022.
//
//  Elements encapsulate selector logic and return a single, or multiple, elements to an
//  Action. Element methods should never interact with anything on the page/inside a view:
//  they exist soley as a means for abstracting away page/view selector logic from test
//  assertions and state changes.

import XCTest

enum PermissionElements {
    private static let app = XCUIApplication()
    private static let springboardApp = XCUIApplication(bundleIdentifier: "com.apple.springboard")
    
    // Might be worth having all springboard elements in a single dedicated
    // springboard elements file
    
    static func authorizeCameraButton() -> XCUIElement {
        return app.buttons["btn_authorize_camera"]
    }
    
    static func authorizeLocationButton() -> XCUIElement {
        return app.buttons["btn_authorize_location"]
    }
    
    static func continueButton() -> XCUIElement {
        return app.buttons["btn_continue"]
    }
    
    static func allowLocationButton() -> XCUIElement {
        return springboardApp.alerts.buttons["Allow While Using App"]
    }
    
    static func allowCameraButton() -> XCUIElement {
        return springboardApp.alerts.buttons["OK"]
    }
    
    static func cameraCheckmarkImage() -> XCUIElement {
        return app.images["img_checkmark_camera"]
    }
    
    static func locationCheckmarkImage() -> XCUIElement {
        return app.images["img_checkmark_location"]
    }
}
