//
//  PermissionsTasks.swift
//  FantasmoSDKUITests
//
//  Created by Fantasmo QA on 27/4/2022.
//
//  Tasks are objects which encapsulate any action which needs to be executed in order to
//  complete that particular task. The job of a Task is to allow the author of a test to
//  achieve some behaviour in a single line of code; without having to explicitly direct the
//  test on what to interact with, and how to interact with it. As such, Tasks should exhibit
//  a behavioural interface.

import XCTest

//  Task objects must conform to the Task protocol in order to be accepted by an Actor

struct AuthorizeCamera: Task {
    func perform() {
        PermissionActions.tapAuthorizeCameraButton()
        PermissionActions.tapAllowCameraButton()
    }
    
    static func permission() -> AuthorizeCamera {
        return AuthorizeCamera()
    }
}

struct AuthorizeLocation: Task {
    func perform() {
        PermissionActions.tapAuthorizeLocationButton()
        PermissionActions.tapAllowWhileUsingAppButton()
    }
    
    static func permission() -> AuthorizeLocation {
        return AuthorizeLocation()
    }
}
