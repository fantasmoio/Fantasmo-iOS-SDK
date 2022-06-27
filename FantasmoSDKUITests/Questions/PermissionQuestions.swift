//
//  PermissionQuestions.swift
//  FantasmoSDKUITests
//
//  Created by Fantasmo QA on 27/4/2022.
//
//  Questions are where the test assertions happen. Questions pertain to a specific domain
//  of an application (just like our Actions, Elements, and Tasks do) and allow Actors to
//  enquire about current state. Questions are idempotent (they are "read only", in
//  database operations speak). Asking the same question 10 times over should always give
//  the same answer, asynchronous/underlying state changes notwithstanding.

import XCTest

enum Permissions: Question {
    case authorized(_ actual: Bool, _ expected: Bool)
    
    func ask() {
        switch self {
            case .authorized(let actualValue, let expectedValue):
                XCTAssertEqual(actualValue, expectedValue)
        }
    }
    
    static func cameraAuthorized(is expectedValue: Bool) -> Permissions {
        let actualValue = PermissionElements.cameraCheckmarkImage().isHittable
        return authorized(actualValue, expectedValue)
    }
    
    static func locationAuthorized(is expectedValue: Bool) -> Permissions {
        let actualValue = PermissionElements.locationCheckmarkImage().isHittable
        return authorized(actualValue, expectedValue)
    }
}
