//
//  Scope.swift
//  
//
//  Created by Jason Jobe on 12/6/22.
//

public protocol DynamicValue {
    func update(with: ScopeValues)
}

public struct ScopeValues {
    var values: [AnyHashable: Any] = [:]
    
    func _get<V>(key: String = #function, default dv: V,
                 _file: String = #fileID, _line: Int = #line
    ) -> V {
        values[key] as? V ?? dv
    }
    
    mutating func _set<V>(key: String = #function, _ value: V) {
        values[key] = value
    }
    
    subscript<V>(_ key: String, as t: V.Type = V.self) -> V? {
        values[key] as? V
    }
}

@propertyWrapper
public struct Scope<Value>: SetEnvironment {
    var keyPath: KeyPath<ScopeValues, Value>
    @Box fileprivate var value: Value?
    //    @Box fileprivate var values: ScopeValues?
    
    public init(_ keyPath: KeyPath<ScopeValues, Value>) {
        self.keyPath = keyPath
    }
    
    public init(wrappedValue: Value, _ keyPath: KeyPath<ScopeValues, Value>) {
        self.keyPath = keyPath
        self.value = wrappedValue
    }
    
    public var wrappedValue: Value {
        value ?? ScopeValues.defaultValues[keyPath: keyPath]
    }
    
    func set(environment: ScopeValues) {
        value = environment[keyPath: keyPath]
    }
}

extension ScopeValues {
    /// This gives us access to all the defaultValues
    static let defaultValues = ScopeValues()
}

#if UI
@propertyWrapper
public struct Model<Value>: DynamicValue {
    
    private var box: Box<Value>
    @Scope(\.self) var env
    
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
    
    public func update(with env: ScopeValues) {
        env.install(on: box.wrappedValue)
    }
}
#endif
