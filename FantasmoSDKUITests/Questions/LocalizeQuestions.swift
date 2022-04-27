//
//  LocalizeQuestions.swift
//  FantasmoSDKUITests
//
//  Created by Fantasmo QA on 2/5/2022.
//

import XCTest

enum Localize: Question {
    case state(_ actual: SwitchState, _ expected: SwitchState)
    case label(_ actual: String, _ expected: String)
    case result(_ actual: String, _ expected: String)
    
    func ask() {
        switch self {
        case .state(let actualValue, let expectedValue):
            XCTAssertEqual(actualValue, expectedValue)
        
        case .label(let actualValue, let expectedValue):
            XCTAssertEqual(actualValue, expectedValue)
            
        case .result(let actualValue, let expectedValue):
            XCTAssert(actualValue.localizedStandardContains(expectedValue))
        }
    }
    
    private static func getState(_ toggle: XCUIElement) -> SwitchState {
        if ((toggle.value as? String) == "1") {
            return SwitchState.On
        }
        return SwitchState.Off
    }
    
    static func ToggleState(of toggle: LocalizeSwitch, is expectedValue: SwitchState) -> Localize {
        let actualValue = getState(LocalizeElements.getSwitch(toggle))
        return state(actualValue, expectedValue)
    }
    
    static func LocalizeButtonLabel(is expectedValue: String) -> Localize {
        let actualValue = LocalizeElements.localizeButton().label
        return label(actualValue, expectedValue)
    }
    
    static func ResultsContain(_ expectedValue: String) -> Localize {
        let results = LocalizeElements.localizeResults().value as! String
        return result(results, expectedValue)
    }
}
