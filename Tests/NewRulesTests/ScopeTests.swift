//
//  Test.swift
//  NewRules
//
//  Created by Jason Jobe on 8/18/24.
//

import Testing
@testable import NewRules

struct Test {

    @Test func testScope() async throws {
        @ScopeValue var flag: Bool = true
        print(flag)
        flag = false
        print(flag, _flag.defaultValue)
    }

    @Test func testDefaultValues() {
        var values = ScopeValues()
        values.name = "fred"
        print(values.name, values(defaultValue: \.name))
    }
}

extension ScopeValues {
    var version: String {
        get { _get(default: "0.0.1") }
        mutating set { _set(newValue) }
    }
}
 
extension ScopeValues {
    
    func callAsFunction<Value>(defaultValue kp: KeyPath<Self, Value>) -> Value {
        ScopeValues.defaultValue(for: kp)
    }
    
    static func defaultValue<Value>(for kp: KeyPath<Self, Value>) -> Value {
        _empty[keyPath: kp]
    }
    static let _empty = ScopeValues()
}

struct ScopeModifier {
    var _transform: (inout ScopeValues) -> Void

    func clone(scope: ScopeValues) -> ScopeValues {
        var copy = scope
        _transform(&copy)
        return copy
    }

    func transform(scope: inout ScopeValues) {
        _transform(&scope)
    }
    
    init(_transform: @escaping (inout ScopeValues) -> Void) {
        self._transform = _transform
    }
    
    /// This method merges into a single Modifier that applies the other updates
    /// and then applies its own, following the View Modifer nesting logic.
    func modifier(_ other: ScopeModifier) -> ScopeModifier {
        ScopeModifier { s in
            other._transform(&s)
            // The inner modifier should win / take precedence
            _transform(&s)
        }
    }
}

// MARK: ScopeValue Test Examples
extension ScopeValues {
    var name: String {
        get { _get(default: "") }
        mutating set { _set(newValue) }
    }
}

extension ScopeValues {
    @ScopeValue static var count: Int = 0
}


@propertyWrapper
class ScopeValue<T> {
    var defaultValue: T
    
    var wrappedValue: T
    init(wrappedValue: T) {
        self.defaultValue = wrappedValue
        self.wrappedValue = wrappedValue
    }
}
