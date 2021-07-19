//
//  ObservationToken.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 19.07.2021.
//

import Foundation

public class ObservationToken {
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
