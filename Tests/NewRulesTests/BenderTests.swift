//
//  Test.swift
//  NewRules
//
//  Created by Jason Jobe on 7/31/25.
//

import Testing
import Benders

/**
 Experiment with
 ```
 struct Bender<Tag> {
 func callAsFunction() -> OpenKeypath
 }
 
 */
//struct TestBenders {

@Test func bender() async throws {
    let values: [String: Any] = [
        "name": "Judy",
        "count": 16
    ]
    let cmd = CommandTest(name: "Jane", count: 21)
    print(cmd)
    try ArgumentInstall(on: cmd, context:values)
    print(cmd)
}

//}

struct CommandTest {
    @Argument var name: String
    @Argument var count: Int
}

protocol _Argument {
    var  _argumentType: Any.Type { get }
    func set<V>(value: V) throws
}

extension _Argument {
    var _argumentType: Any.Type { type(of: self) }
}

protocol ConstructableFromString {
    static func make(from: String) -> Self
}

extension Int: ConstructableFromString {
    static func make(from str: String) -> Int {
        Int(str) ?? 0
    }
}

@propertyWrapper
final class Argument<Value>: _Argument, CustomStringConvertible {
    var wrappedValue: Value
    
    init(wrappedValue: Value) {
        self.wrappedValue = wrappedValue
    }
    
    var description: String { String(describing: wrappedValue) }
  
    public enum Report: Error {
        case badValue(String, expecting: String)
        
        static func bad<V,T>(value: V, expecting: T.Type) -> Self {
            .badValue(
                String(describing: value),
                expecting: String(describing: T.self))
        }
    }
 
    func set<A>(value: A) throws {
        if let sv = value as? String,
           let f = Value.self as? ConstructableFromString.Type,
           let nv = f.make(from: sv) as? Value
        {
            wrappedValue = nv
        } else if let nv = value as? Value {
            wrappedValue = nv
        }
        else { throw Report.bad(value: value, expecting: Value.self) }
    }
}

public func ArgumentInstall<A>(on: A, context: [String:Any]) throws {
    let m = Mirror(reflecting: on)
    for child in m.children {
        if let e = child.value as? _Argument,
           let key = child.label,
           let v = context[key.dropFirst().description]
        {
            try e.set(value: v)
        }
    }
}
