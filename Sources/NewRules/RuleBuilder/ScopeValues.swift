//
//  EnvironmentValue.swift
//
//
//  Created by Chris Eidhof on 31.05.21.
//

import Foundation
import OSLog

// MARK: Logger Environment Value
struct LoggerKey: ScopeKey {
    static var defaultValue: Logger = Logger(subsystem: "com.wildthink", category: "rules")
}

extension ScopeValues {
    public var os_log: Logger {
        get { self[LoggerKey.self] }
        set { self[LoggerKey.self] = newValue }
    }
}

// MARK: Environment Implementation and Modifier Rule
struct EnvironmentModifier<A, Content: Rule>: Builtin {
    init(content: Content, keyPath: WritableKeyPath<ScopeValues, A>, modify: @escaping (inout A) -> ()) {
        self.content = content
        self.keyPath = keyPath
        self.modify = modify
    }
    
    var content: Content
    var keyPath: WritableKeyPath<ScopeValues, A>
    var modify: (inout A) -> ()
    
    func run(environment: ScopeValues) throws {
        var copy = environment
        modify(&copy[keyPath: keyPath])
        try content.builtin.run(environment: copy)
    }
}

public extension Rule {
    func environment<A>(keyPath: WritableKeyPath<ScopeValues, A>, value: A) -> some Rule {
        EnvironmentModifier(content: self, keyPath: keyPath, modify: { $0 = value })
    }
    
    func modifyEnvironment<A>(
        keyPath: WritableKeyPath<ScopeValues, A>,
        modify: @escaping (inout A) -> ()
    ) -> some Rule {
        EnvironmentModifier(content: self, keyPath: keyPath, modify: modify )
    }
}

extension ScopeValues {
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
    func set(environment: ScopeValues)
}

public protocol ScopeKey {
    associatedtype Value
    static var defaultValue: Value { get }
}

extension ScopeValues {
    public subscript<Key: ScopeKey>(key: Key.Type = Key.self) -> Key.Value {
        get {
            values[ObjectIdentifier(key)] as? Key.Value ?? Key.defaultValue
        }
        set {
            values[ObjectIdentifier(key)] = newValue
        }
    }
}
