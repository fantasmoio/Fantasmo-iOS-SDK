//
//  FMFrameEvaluator.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 21.02.22.
//

import Foundation

protocol FMFrameEvaluator: AnyObject {
    /// performs in-place evaluation
    /// when evaluation is succesful, sets `FMFrameEvaluation` object on frame
    func evaluate(frame: FMFrame)
}
