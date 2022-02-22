//
//  FMFrameEvaluator.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 21.02.22.
//

import Foundation

protocol FMFrameEvaluator: AnyObject {
    /// in-place evaluation, should set FMFrameEvaluation object on frame
    func evaluate(frame: FMFrame)
}
