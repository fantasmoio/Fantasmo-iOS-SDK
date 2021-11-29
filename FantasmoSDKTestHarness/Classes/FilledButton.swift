//
//  FilledButton.swift
//  FantasmoSDKTestHarness
//
//  Created by Nick Jensen on 01.11.21.
//

import UIKit

class FilledButton: UIButton {
    override public var isEnabled: Bool {
        didSet {
            let alpha = isEnabled ? 1.0 : 0.5
            backgroundColor = backgroundColor?.withAlphaComponent(alpha)
        }
    }
}
