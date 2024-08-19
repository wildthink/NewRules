//
//  EnvironmentValue.swift
//
//
//  Created by Chris Eidhof on 31.05.21.
//

import Foundation
import OSLog

// MARK: Logger Environment Value
struct LoggerKey: EnvironmentKey {
    static var defaultValue: Logger = Logger(subsystem: "com.wildthink", category: "rules")
}

extension EnvironmentValues {
    public var os_log: Logger {
        get { self[LoggerKey.self] }
        set { self[LoggerKey.self] = newValue }
    }
}

// MARK: Environment Implementation and Modifier Rule
struct EnvironmentModifier<A, Content: Rule>: Builtin {
    init(content: Content, keyPath: WritableKeyPath<EnvironmentValues, A>, modify: @escaping (inout A) -> ()) {
        self.content = content
        self.keyPath = keyPath
        self.modify = modify
    }
    
    var content: Content
    var keyPath: WritableKeyPath<EnvironmentValues, A>
    var modify: (inout A) -> ()
    
    func run(environment: EnvironmentValues) throws {
        var copy = environment
        modify(&copy[keyPath: keyPath])
        try content.builtin.run(environment: copy)
    }
}

public extension Rule {
    func environment<A>(keyPath: WritableKeyPath<EnvironmentValues, A>, value: A) -> some Rule {
        EnvironmentModifier(content: self, keyPath: keyPath, modify: { $0 = value })
    }
    
    func modifyEnvironment<A>(
        keyPath: WritableKeyPath<EnvironmentValues, A>,
        modify: @escaping (inout A) -> ()
    ) -> some Rule {
        EnvironmentModifier(content: self, keyPath: keyPath, modify: modify )
    }
}

extension EnvironmentValues {
    func install<A>(on: A) {
        let m = Mirror(reflecting: on)
        for child in m.children {
            if let e = child.value as? SetEnvironment {
                e.set(environment: self)
            }
        }
    }
}

@propertyWrapper
class Box<A>: ObservableObject {
    var wrappedValue: A
    init(wrappedValue: A) {
        self.wrappedValue = wrappedValue
    }
}

protocol SetEnvironment {
    func set(environment: EnvironmentValues)
}

//@propertyWrapper
//public struct Environment<Value>: SetEnvironment {
//    var keyPath: KeyPath<EnvironmentValues, Value>
//    @Box fileprivate var values: EnvironmentValues?
//    
//    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
//        self.keyPath = keyPath
//    }
//    
//    public var wrappedValue: Value {
//        values![keyPath: keyPath]
//    }
//    
//    func set(environment: EnvironmentValues) {
//        values = environment
//    }
//}

// MARK:
//#if canImport(SwiftUI)
//import SwiftUI
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

