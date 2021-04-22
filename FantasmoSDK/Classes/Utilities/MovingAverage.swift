//
//  MovingAverage.swift
//  Fantasmo-iOS-SDK-Test-Harness
//
//  Created by lucas kuzma on 3/30/21.
//

class MovingAverage {
    
    private var index = 0
    private let period: Int
    private var samples: Array<Double>
    
    init(period: Int = 30) {
        self.period = period
        samples = []
    }
    
    var average: Double {
        let sum = samples.reduce(0.0, +)
        return sum / Double(samples.count)
    }
    
    func addSample(value: Double) -> Double {
        if samples.count == period {
            samples[index] = value
            index = (index + 1) % period
        } else {
            samples.append(value)
        }
        
        return average
    }
}
