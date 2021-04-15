//
//  FMInputQualityFilter.swift
//  FantasmoSDK
//
//  Created by lucas kuzma on 3/30/21.
//

import ARKit

/// Used to determine which frames in sequence of frames can be used for determining location.
/// All frames  are expected to be passed sequentially to `validate(_)` method keeping their order in sequence.
/// If necessary to start new sequence `prepareForNewFrameSequence()` must be invoked.
class FMFrameSequenceGuard {
    
    private var timestampOfPreviousApprovedFrame: TimeInterval?
    
    /// Number of seconds after which we force approval.
    private var acceptanceThreshold = 6.0
    
    /// Filter collection, in order of increasing computational cost
    private let validators: [FMFrameValidator] = [
        FMCameraPitchValidator(),
        FMMovementValidator(),
        FMBlurValidator(),
    ]
    
    /// Check whether passed `frame` can be used for determining location.
    /// Frame is assessed for quality by various aspects before approval but is approved without any assessment if the last successfully validated
    /// frame was passed in too long ago.
    /// If it is needed to start working with new sequence of frames then invoke `prepareForNewFrameSequence()` or create new instance
    /// of this class.
    func validate(_ frame: ARFrame) -> Result<Void, FMFrameValidationError> {
        if shouldForceApprove(frame) {
            timestampOfPreviousApprovedFrame = frame.timestamp
            return .success(())
        }
        
        for validator in validators {
            if case let .failure(rejection) = validator.validate(frame) {
                return .failure(rejection)
            }
        }

        timestampOfPreviousApprovedFrame = frame.timestamp
        return .success(())
    }
    
    /// Invoke this method when it is needed to start validating a new sequence of frames.
    /// Invoking this method will ensure that first frame on the new sequence will not be force approved without any assessing for quality.
    func prepareForNewFrameSequence() {
        timestampOfPreviousApprovedFrame = nil
    }

    /// If there are a lot of continuous rejections, we force an acceptance
    private func shouldForceApprove(_ frame: ARFrame) -> Bool {
        guard let prevTimestamp = timestampOfPreviousApprovedFrame else { return false }
        
        let elapsed = frame.timestamp - prevTimestamp
        return elapsed > acceptanceThreshold
    }

}
