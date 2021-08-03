//
//  Array+Extension.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 8/3/21.
//

import Foundation

extension Array where Element == Double {
    func median() -> Double? {
        guard count > 0  else { return nil }

        let sorted = self.sorted()
        if count % 2 != 0 {
            return sorted[count/2]
        } else {
            return (sorted[count/2] + sorted[count/2 - 1]) / 2.0
        }
    }
}
