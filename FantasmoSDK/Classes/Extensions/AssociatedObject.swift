//
//  AssociatedObject.swift
//  FantasmoSDK
//
//  Created by Yauheni Klishevich on 18.05.2021.
//

import Foundation
import ObjectiveC

/// Allows to add associated property of any type to some class in an extension.
/// It is impossible to add associated property to value type (https://bit.ly/3g3zhzs)
/// Alternative approach could be https://bit.ly/34CeU7q (in case if there will be any problems with properties of Value types)
func setAssociatedObject<T>(object: AnyObject,
                            value: T,
                            associativeKey: UnsafeRawPointer,
                            policy: objc_AssociationPolicy) {
    
    /// `Any` can be bridged to `SwiftValue` (https://bit.ly/3fXIvNX)
    let v = value as AnyObject
    objc_setAssociatedObject(object, associativeKey, v, policy)
}

func getAssociatedObject<T>(object: AnyObject, associativeKey: UnsafeRawPointer) -> T? {
    if let v = objc_getAssociatedObject(object, associativeKey) as? T {
        return v
    }
    else {
        return nil
    }
}
