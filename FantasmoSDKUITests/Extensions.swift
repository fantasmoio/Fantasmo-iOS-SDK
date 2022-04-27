//
//  Extensions.swift
//  FantasmoSDKUITests
//
//  Created by Fantasmo QA on 3/5/2022.
//

import XCTest

extension XCUIApplication {
    // Uninstalls the AUT (needed for permission, storage, and cache clears)
    // Edited from: https://www.jessesquires.com/blog/2021/10/25/delete-app-during-ui-tests/
    func uninstall() {
        self.terminate()

        let timeout = TimeInterval(5)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

        let appName = AUTName

        /// use `firstMatch` because icon may appear in iPad dock
        let appIcon = springboard.icons[appName].firstMatch
        if appIcon.waitForExistence(timeout: timeout) {
            appIcon.press(forDuration: 2)
        } else {
            XCTFail("Failed to find app icon named \(appName)")
        }

        let removeAppButton = springboard.buttons["Remove App"]
        if removeAppButton.waitForExistence(timeout: timeout) {
            removeAppButton.tap()
        } else {
            XCTFail("Failed to find 'Remove App'")
        }

        let deleteAppButton = springboard.alerts.buttons["Delete App"]
        if deleteAppButton.waitForExistence(timeout: timeout) {
            deleteAppButton.tap()
        } else {
            XCTFail("Failed to find 'Delete App'")
        }

        let finalDeleteButton = springboard.alerts.buttons["Delete"]
        if finalDeleteButton.waitForExistence(timeout: timeout) {
            finalDeleteButton.tap()
        } else {
            XCTFail("Failed to find 'Delete'")
        }
    }
}

// Check if any permissions need to be granted before we start UI tests
extension XCUIApplication {
    public func grantNeededPermissions() {

        let btnExpectation = XCTKVOExpectation(keyPath: "exists", object: PermissionElements.continueButton(), expectedValue: true)

        let btnResult = XCTWaiter.wait(for: [btnExpectation], timeout: 2.0)

        /// if the continue button doesn't exist 2 seconds after app launch we assume permissions already granted
        guard btnResult == XCTWaiter.Result.completed else {
            return
        }

        if PermissionElements.authorizeCameraButton().isHittable {
            PermissionActions.tapAuthorizeCameraButton()
            PermissionActions.tapAllowCameraButton()
        }

        if PermissionElements.authorizeLocationButton().isHittable {
            PermissionActions.tapAuthorizeLocationButton()
            PermissionActions.tapAllowWhileUsingAppButton()
        }

        PermissionActions.tapContinueButton()
    }
}

extension XCUIElement {
    /// Ensures an element exists and is also hittable
    @discardableResult
    func waitForHittable(timeout: TimeInterval = UITestTimeout.element) -> Bool {
        return waitForExistence(timeout: timeout) && isHittable
    }
}

extension XCUIElement {
    /// Tap an element when it becomes hittable
    func tapWhenHittable(timeout: TimeInterval = UITestTimeout.element) {
        waitForHittable(timeout: timeout)
        tap()
    }
}

extension XCUIElement {
    /// Tap an element that is on screen but for some reason reports as unhittable
    func forceTapElement() {
        if isHittable {
            tap()
        }
        else {
            let coordinate: XCUICoordinate = coordinate(withNormalizedOffset: CGVector(dx:0.5, dy:0.5))
            coordinate.tap()
        }
    }
}
