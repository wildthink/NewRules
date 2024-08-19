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
    
    @Test func testWrapper() throws {
        let tv = TestView()
//        print(tv.key, tv.testProp, tv.$testProp.str)
        tv.testProp = 43
        print(tv.key, tv.testProp as Any)
    }

    @Test func testDefaultValues() {
        var values = ScopeValues()
        values.name = "fred"
        print(values.name, values(defaultValue: \.name))
    }
}

//import SwiftUIs

extension ScopeValues {
    var version: String {
        get { _get(default: "0.0.1") }
        mutating set { _set(newValue) }
    }
}

//extension ScopeValues {
//    @Entry
//    var name: String = "jane"
//}


//extension ScopeValues {
//    // @Entry
//    var name: String // = "jane"
//    {
//        get {
//            self[__Key_name.self]
//        }
//        set {
//            self[__Key_name.self] = newValue
//        }
//    }
//    private struct __Key_name: SwiftUICore.ScopeKey {
//        typealias Value = String
//        static var defaultValue: Value { "jane" }
//    }
//}
 
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

// https://swiftbysundell.com/articles/accessing-a-swift-property-wrappers-enclosing-instance/
//https://forums.swift.org/t/property-wrappers-access-to-both-enclosing-self-and-wrapper-instance/32526

@propertyWrapper
public final class Wrapper<Value> {
    
    public static subscript<EnclosingSelf>(
        _enclosingInstance observed: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value?>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Wrapper>
    ) -> Int? {
        get {
            return observed[keyPath: storageKeyPath].stored
        }
        set {
            let oldValue = observed[keyPath: storageKeyPath].stored
            if newValue != oldValue {
                // TODO: call wrapper instance with enclosing self
            }
            if let tv = observed as? TestView {
                print(#line, tv.key)
            }
            observed[keyPath: storageKeyPath].stored = newValue
        }
    }
    
    @available(*, unavailable, message: "Proxy should be in a class")
    public var wrappedValue: Value? {
        get { fatalError("called wrappedValue getter") }
        set { fatalError("called wrappedValue setter") }
    }
    
    public init(wrappedValue: Value?, str: String) {
        self.str = str
    }
    
    public init(str: String) {
        self.str = str
    }
    
    // MARK: - Private
    public var projectedValue: Wrapper<Value> {
        return self
    }
    
    let str: String
    var stored: Int?
}

class TestView {
    @Wrapper(str: "HelloWorld") public var testProp: Int? = 23
    var key: String = "_key"
}

/**
 Swift Compiler Error
 Type '_' has no member 'testProp'
 */
