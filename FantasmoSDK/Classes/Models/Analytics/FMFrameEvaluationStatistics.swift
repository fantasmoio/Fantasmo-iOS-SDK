//
//  FMFrameEvaluationStatistics.swift
//  FantasmoSDK
//
//  Created by Nicholas Jensen on 09.03.22.
//

import Foundation

/// Model containing statistics about frame evaluations peformed in a localization session.
class FMFrameEvaluationStatistics {
    
    /// Model representing a single frame evaluation window
    class Window {
        
        let start: Date
        
        var currentScore: Float?
        
        var currentBestScore: Float?
        
        var currentRejectionReason: FMFrameFilterRejectionReason?
        
        var evaluations: Int = 0
         
        var rejections: Int = 0
                        
        init(_ start: Date) {
            self.start = start
        }
    }
    
    /// Type of evaluation done in the session.
    public let type: FMFrameEvaluationType
    
    /// Ordered list of evaluation windows in the session, last window being the newest.
    public private(set) var windows: [Window] = []
    
    /// Highest score evaluated in the session.
    public private(set) var highestScore: Float?
    
    /// Lowest score evaluated in the session.
    public private(set) var lowestScore: Float?
    
    /// Sum of all scores evaluated in the session.
    public private(set) var sumOfAllScores: Float = 0
    
    /// Total evaluations in the session.
    public private(set) var totalEvaluations: Int = 0
    
    /// Total rejections in the session.
    public private(set) var totalRejections: [FMFrameFilterRejectionReason: Int] = [
        .pitchTooLow: 0,
        .pitchTooHigh: 0,
        .movingTooFast: 0,
        .movingTooLittle: 0,
        .insufficientFeatures: 0
    ]
    
    /// Designated constructor.
    init(type: FMFrameEvaluationType) {
        self.type = type
    }
    
    /// Creates a new window and makes it the current window.
    public func startWindow(at startDate: Date) {
        windows.append(Window(startDate))
    }
    
    /// Adds evaluation data from the given frame to the current window and updates statistics.
    public func addEvaluation(frame: FMFrame) {
        guard let evaluation = frame.evaluation, let window = windows.last else {
            return
        }
        
        // Update global session stats
        totalEvaluations += 1
        sumOfAllScores += evaluation.score
        if highestScore == nil || evaluation.score > highestScore! {
            highestScore = evaluation.score
        }
        if lowestScore == nil || evaluation.score < lowestScore! {
            lowestScore = evaluation.score
        }
        
        // Update current window stats
        window.evaluations += 1
        window.currentScore = evaluation.score
        window.currentRejectionReason = nil
    }
    
    /// Sets the best frame for the current window.
    public func setCurrentBest(frame: FMFrame) {
        guard let evaluation = frame.evaluation, let window = windows.last else {
            return
        }
        
        window.currentBestScore = evaluation.score
    }
    
    /// Increment the count for a specific filter rejection and set as the current rejection.
    public func addFilterRejection(_ rejectionReason: FMFrameFilterRejectionReason) {
        guard let window = windows.last else {
            return
        }
        // Add to session totals
        totalRejections[rejectionReason]! += 1
        
        // Add to current window
        window.rejections += 1
        window.currentRejectionReason = rejectionReason
    }
    
    /// Reset all statistics, used when starting a new session.
    public func reset() {
        windows.removeAll()
        highestScore = nil
        lowestScore = nil
        sumOfAllScores = 0
        totalEvaluations = 0
        totalRejections.forEach { k, v in totalRejections[k] = 0 }
    }
}
