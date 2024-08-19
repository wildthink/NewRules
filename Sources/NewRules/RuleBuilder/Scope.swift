//
//  Scope.swift
//  
//
//  Created by Jason Jobe on 12/6/22.
//

import SwiftUI

public protocol DynamicValue {
    func update(with: EnvironmentValues)
}

//protocol EnvironmentSettable {
//    func set(values: EnvironmentValues)
//}

// MARK: - objc.io
@propertyWrapper
struct _Scope<Value>: DynamicValue, DynamicProperty {
    var keyPath: KeyPath<EnvironmentValues, Value>
    var defaultValue: () -> Value
    @Box var value: Value? = nil
    
    init(wrappedValue defaultValue: Value, _ keyPath: KeyPath<EnvironmentValues, Value>) {
        self.keyPath = keyPath
        self.defaultValue = { defaultValue }
    }
    
    init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
        self.keyPath = keyPath
        self.defaultValue = { EnvironmentValues.current[keyPath: keyPath] }
    }
    
    func update(with values: EnvironmentValues) {
        self.value = values[keyPath: keyPath]
    }
    
    var wrappedValue: Value {
        return value ?? defaultValue()
    }
}

extension EnvironmentValues: @unchecked Sendable {
    @TaskLocal public static var current = Self()
}

//extension EnvironmentValues {
//    func install<A>(on obj: A) {
//        let m = Mirror(reflecting: obj)
//        for child in m.children {
//            if let envProperty = (child.value as? EnvironmentSettable) {
//                envProperty.set(values: self)
//            }
//        }
//    }
//}

//@propertyWrapper
//class ScopeValue<T> {
//    var defaultValue: T
//    
//    var wrappedValue: T
//    init(wrappedValue: T) {
//        self.defaultValue = wrappedValue
//        self.wrappedValue = wrappedValue
//    }
//}
//
//func sv() {
//    @ScopeValue var flag: Bool = true
//    print(flag)
//}

//protocol SetEnvironment {
//    func set(environment: EnvironmentValues)
//}

//@propertyWrapper
//public struct Scope<Value>: SetEnvironment {
//    var keyPath: KeyPath<EnvironmentValues, Value>
//    @Box fileprivate var value: Value?
////    @Box fileprivate var values: EnvironmentValues?
//
//    public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
//        self.keyPath = keyPath
//    }
//    
//    public init(wrappedValue: Value, _ keyPath: KeyPath<EnvironmentValues, Value>) {
//        self.keyPath = keyPath
//        self.value = wrappedValue
//    }
//
//    public var wrappedValue: Value {
//        // if Value was NOT optional then we would
//        // guard let values else { fatalError }
//        value ?? EnvironmentValues.current[keyPath: keyPath]
//    }
//    
//    func set(environment: EnvironmentValues) {
//        value = environment[keyPath: keyPath]
//    }
//}

@propertyWrapper
public struct Model<Value>: DynamicProperty {
    @StateObject private var box: Box<Value>
    @Environment(\.self) var env
    
    public var wrappedValue: Value {
        get { box.wrappedValue }
        nonmutating set { box.wrappedValue = newValue }
    }
    
    public var projectedValue: Binding<Value> {
        Binding(
            get: { wrappedValue },
            set: { box.wrappedValue = $0 }
        )
    }
    
    public func update() {
        env.install(on: box.wrappedValue)
    }
}
