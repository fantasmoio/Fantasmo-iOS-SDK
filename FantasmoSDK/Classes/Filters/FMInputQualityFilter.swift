//
//  FMInputQualityFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

protocol FMFrameFilter {
    func accepts(_ frame: ARFrame) -> Bool
}

class FMInputQualityFilter: FMFrameFilter {
    
    let filters: [FMFrameFilter] = [
        FMAngleFilter()
    ]
    
    func accepts(_ frame: ARFrame) -> Bool {
        for filter in filters {
            if !filter.accepts(frame) {
                return false
            }
        }
        return true
    }
}
