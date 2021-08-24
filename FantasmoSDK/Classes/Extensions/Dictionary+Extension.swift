//
//  Dictionary+Extension.swift
//  FantasmoSDK
//
//

import Foundation

extension Dictionary {
    var json: String {
        let invalidJson = "Not a valid JSON"
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: [])
            return String(bytes: jsonData, encoding: String.Encoding.utf8) ?? invalidJson
        } catch {
            return invalidJson
        }
    }
}

extension Dictionary where Key == UUID {
    
    /// Used for implementing property observers, when we usually put observation closure into a dictionary under some key.
    mutating func insert(_ value: Value) -> UUID {
        let id = UUID()
        self[id] = value
        return id
    }
}

extension Dictionary where Key: CaseIterable {
    
    /// Initialize dictionary with all possible values of keys and the passed `initialValueForAllCases` as a corresponding value for each of them.
    init(initialValueForAllCases: Value) {
        self.init()
        Key.allCases.forEach { aKey in
            self[aKey] = initialValueForAllCases
        }
    }
}

