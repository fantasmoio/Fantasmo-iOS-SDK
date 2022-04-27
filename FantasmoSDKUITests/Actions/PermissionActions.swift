//
//  PermissionActions.swift
//  FantasmoSDKUITests
//
//  Created by Fantasmo QA on 27/4/2022.
//
//  Actions are static methods which encapsulate the implementation details of how to
//  interact with elements using XCTest. There should be no assertions here.

import XCTest

enum PermissionActions {    
    static func tapAuthorizeCameraButton() {
        PermissionElements.authorizeCameraButton().tapWhenHittable()
    }
    
    static func tapAuthorizeLocationButton() {
        PermissionElements.authorizeLocationButton().tapWhenHittable()
    }
    
    static func tapAllowCameraButton() {
        PermissionElements.allowCameraButton().tapWhenHittable()
    }
    
    static func tapAllowWhileUsingAppButton() {
        PermissionElements.allowLocationButton().tapWhenHittable()
    }
    
    static func tapContinueButton() {
        PermissionElements.continueButton().tapWhenHittable()
    }
}
