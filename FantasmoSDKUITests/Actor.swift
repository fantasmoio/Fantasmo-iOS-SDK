//
//  Actor.swift
//  FantasmoSDKUITests
//
//  Created by Fantasmo QA on 27/4/2022.
//
//  An actor is the "person" (or thing) interacting with the AUT. The actor has a set
//  of actions available to them in the form of tasks and can ask questions about the state
//  of the AUT.

import XCTest

public class Actor {
    let name: String
    
    public init(called name: String) {
        self.name = name
    }
    
    // MARK: Public
    
    /// Make this Actor perform a setup task.
    ///
    /// Interacts with the application by performing the given `task`.
    ///
    /// - Parameter task: Task to be performed.
    public func has(_ task: Task) {
        perform(task)
    }
    
    /// Make this Actor perform a task which should cause your expected outcome.
    ///
    /// Interacts with the application by performing the given `task`.
    ///
    /// - Parameter task: Task to be performed.
    public func attemptsTo(_ task: Task) {
        perform(task)
    }
    
    /// Ask a question about what this Actor sees on the screen to verify that it is what you expect.
    ///
    /// Enquires about the state of the application using the given `question`.
    ///
    /// - Parameter question: Question to be answered.
    public func sees(_ question: Question) {
        ask(question)
    }
    
    /// Wait until a specific property of a given element becomes 'value'.
    ///
    /// The ability of the actor to wait is what allows them to enquire about the state of the application at the right time.
    /// This will fail a test if the result is anything other than what was expected.
    ///
    /// - Parameter element: The XCUIElement to check
    /// - Parameter property: The property (keyPath) of the element we are inspecting
    /// - Parameter value: The value we expected the property to be
    @discardableResult
    public func waitsUntil(_ element: XCUIElement, _ property: String, is value: Any, for seconds: TimeInterval? = nil) -> XCTWaiter.Result {
        let waitTime = seconds ?? UITestTimeout.element
        let expectation = XCTKVOExpectation(keyPath: property, object: element, expectedValue: value)
        return XCTWaiter.wait(for: [expectation], timeout: waitTime)
    }
    
    // MARK: Private
    
    /// Ask the given question
    private func ask(_ question: Question) {
        question.ask()
    }
    
    /// Performs the given task
    private func perform(_ task: Task) {
        task.perform()
    }
}
