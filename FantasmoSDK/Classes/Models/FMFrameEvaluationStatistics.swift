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
        
        var currentFilterRejection: FMFrameRejectionReason?
        
        var currentImageQualityUserInfo: FMImageQualityUserInfo?
        
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
    
    /// Total time spent evaluating frames in the session.
    public private(set) var totalEvaluationTime: TimeInterval = 0
    
    /// Total evaluations in the session.
    public private(set) var totalEvaluations: Int = 0
    
    /// Dictionary of frame rejection reasons and the number of times each occurred in the session.
    public private(set) var rejectionReasons = [FMFrameRejectionReason: Int].init(initialValueForAllCases: 0)
    
    /// Total rejections in the session.
    public var totalRejections: Int {
        return rejectionReasons.values.reduce(0, +)
    }
    
    // Average of all evaluation scores in the session.
    public var averageEvaluationScore: Float {
        return totalEvaluations > 0 ? sumOfAllScores / Float(totalEvaluations) : 0
    }
    
    // Average time it took to evaluate a single frame in the session
    public var averageEvaluationTime: TimeInterval {
        return totalEvaluations > 0 ? totalEvaluationTime / TimeInterval(totalEvaluations) : 0
    }
    
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
        
        // Update session stats
        totalEvaluations += 1
        totalEvaluationTime += evaluation.time
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
        window.currentImageQualityUserInfo = evaluation.imageQualityUserInfo
        
        // If an evaluation was made, the frame cleared the filters
        window.currentFilterRejection = nil
    }
    
    /// Sets the best frame for the current window.
    public func setCurrentBest(frame: FMFrame) {
        guard let evaluation = frame.evaluation, let window = windows.last else {
            return
        }
        
        window.currentBestScore = evaluation.score
    }
    
    /// Increment the count for a rejection type.
    public func addRejection(_ rejectionReason: FMFrameRejectionReason, filter: FMFrameFilter? = nil) {
        guard let window = windows.last, let rejectionCount = rejectionReasons[rejectionReason] else {
            return
        }
        // Add to session total rejections
        rejectionReasons[rejectionReason] = rejectionCount + 1
        
        // Add to current window rejections
        window.rejections += 1        
        
        if filter != nil {
            // Set the window as currently being blocked by a filter
            window.currentFilterRejection = rejectionReason
        }
    }
    
    /// Reset all statistics, used when starting a new session.
    public func reset() {
        windows.removeAll()
        highestScore = nil
        lowestScore = nil
        sumOfAllScores = 0
        totalEvaluationTime = 0
        totalEvaluations = 0
        rejectionReasons = [FMFrameRejectionReason: Int].init(initialValueForAllCases: 0)
    }
}
