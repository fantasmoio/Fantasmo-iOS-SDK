//
//  FMFrameEvaluator.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 21.02.22.
//

import Foundation

protocol FMFrameEvaluator: AnyObject {
    func evaluate(frame: FMFrame) -> FMFrameEvaluation
}
