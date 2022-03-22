//
//  FMFrameFilter.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 31.05.2021.
//

import ARKit


enum FMFrameFilterResult: Equatable {
    case accepted
    case rejected(reason: FMFrameRejectionReason)
}

protocol FMFrameFilter {
    func accepts(_ frame: FMFrame) -> FMFrameFilterResult
}
