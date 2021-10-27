//
//  ObservationToken.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 19.07.2021.
//

import Foundation

/// Token that is used in the same way as `AnyCancellable` is used in `Combine` framework.
/// Functions for adding closure based observers may return this token to allow unsubscribing.
/// The necessity of the class was driven by accebility of `Combine` framework starting from only iOS 13.0, while SDK deploment target was lower.
class ObservationToken {
    private let cancellationClosure: () -> Void

    init(cancellationClosure: @escaping () -> Void) {
        self.cancellationClosure = cancellationClosure
    }
    
    deinit {
        cancellationClosure()
    }

    func cancel() {
        cancellationClosure()
    }
}
