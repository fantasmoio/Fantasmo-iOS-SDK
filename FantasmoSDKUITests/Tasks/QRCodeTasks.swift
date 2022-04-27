//
//  QRCodeTasks.swift
//  FantasmoSDKUITests
//
//  Created by Fantasmo QA on 11/5/2022.
//

struct SubmitManualQRCode: Task {
    let text: String

    init(_ text: String) {
        self.text = text
    }
    
    func perform() {
        QRCodeActions.tapEnterCodeButton()
        QRCodeActions.enterCode(text)
        QRCodeActions.submitCode()
    }
}

struct ToggleTorchState: Task {
    func perform() {
        QRCodeActions.tapTorchButton()
    }
}
