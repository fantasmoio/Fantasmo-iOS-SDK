//
//  FMFrameEvaluationStatistics.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 09.03.22.
//

import Foundation

/// Accumulator of statistics about frame evaluation peformed in a session
class FMFrameEvaluationStatistics {
    
    /// Type of evaluation done in the session.
    public let type: FMFrameEvaluationType
    
    /// Total frames evaluated in the session.
    public private(set) var count: Int = 0
    
    /// The last, most recent score evaluated in the session.
    public private(set) var lastScore: Float?
    
    /// Highest score evaluated in the session.
    public private(set) var highestScore: Float?
    
    /// Lowest score evaluated in the session.
    public private(set) var lowestScore: Float?
    
    /// Average of all scores evaluated in the session.
    public private(set) var averageScore: Float?
    
    /// Sum of all scores evaluated in the session.
    public private(set) var combinedScores: Float = 0
    
    /// Sum of all time spent evaluating frames.
    public private(set) var totalEvaluationTime: TimeInterval = 0
    
    /// Average time it took to evaluate a single frame.
    public private(set) var averageEvaluationTime: TimeInterval = 0
    
    /// Total frames evaluted to be the current time window's new best frame.
    public var newBestFrame: Int = 0
    
    /// Total frames evaluted below the current time window's best frame.
    public var belowCurrentBestScore: Int = 0
    
    /// Total frames evaluted below the min score threshold.
    public var belowMinScoreThreshold: Int = 0
    
    /// Designated constructor.
    init(type: FMFrameEvaluationType) {
        self.type = type
    }
    
    /// Add an evaluated frame from the current session and update evaluation statistics.
    public func update(withFrame frame: FMFrame) {
        guard let evaluation = frame.evaluation else {
            return
        }
        
        count = max(1, count + 1)
        
        lastScore = evaluation.score
        
        if highestScore == nil || evaluation.score > highestScore! {
            highestScore = evaluation.score
        }
        if lowestScore == nil || evaluation.score < lowestScore! {
            lowestScore = evaluation.score
        }
        
        combinedScores += evaluation.score
        averageScore = combinedScores / Float(count)
        
        totalEvaluationTime += max(0.0, evaluation.timestamp - frame.timestamp)
        averageEvaluationTime = totalEvaluationTime / Double(count)
    }
    
    /// Reset all statistics, used when starting a new session.
    public func reset() {
        count = 0
        lastScore = nil
        highestScore = nil
        lowestScore = nil
        averageScore = nil
        combinedScores = 0
        totalEvaluationTime = 0
        averageEvaluationTime = 0
        newBestFrame = 0
        belowCurrentBestScore = 0
        belowMinScoreThreshold = 0
    }
}
