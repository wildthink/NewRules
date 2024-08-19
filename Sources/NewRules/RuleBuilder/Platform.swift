//
//  Platform.swift
//  NewRules
//
//  Created by Jason Jobe on 8/19/24.
//
//
//#if canImport(SwiftUI)
//@_exported import SwiftUI
//#else
//public protocol EnvironmentKey {
//    associatedtype Value
//    static var defaultValue: Value { get }
//}
//
//public struct EnvironmentValues {
//    
//    var userDefined: [ObjectIdentifier:Any] = [:]
//    
//    public subscript<Key: EnvironmentKey>(key: Key.Type = Key.self) -> Key.Value {
//        get {
//            userDefined[ObjectIdentifier(key)] as? Key.Value ?? Key.defaultValue
//        }
//        set {
//            userDefined[ObjectIdentifier(key)] = newValue
//        }
//    }
//}
//#endif

public typealias EnvironmentValues = ScopeValues

extension EnvironmentValues {
    /// This gives us access to all the defaultValues
    static let defaultValues = EnvironmentValues()
}
