//
//  ExtAnyKeyPath.swift
//  NewRules
//
//  Created by Jason Jobe on 6/23/25.
//
import Foundation

public protocol ExtAnyKeyPath<Subject> {
    associatedtype Subject
}

// MARK: Convenience Operators
prefix operator ^
postfix operator ^

public prefix func ^<V>( x: V.Type) -> ExtPartialKeyPath<V> {
    ExtPartialKeyPath()
}

public postfix func ^<V>( x: V.Type) -> ExtPartialKeyPath<V> {
    ExtPartialKeyPath()
}

public postfix func ^<V>( x: V) -> ExtPartialKeyPath<V> {
    ExtPartialKeyPath()
}

/// The `OpenKeyPath` grants access to the underlying array of keys.
/// We use this indirection so in code, autocomplete on Extended KeyPaths
/// is limited to tranversing the underlying type.
public struct OpenKeyPath {
    var wrapped: any _ExtAnyKeyPath
    
    public init?(_ wrapped: any ExtAnyKeyPath) {
        guard let w = wrapped as? any _ExtAnyKeyPath
        else { return nil }
        self.wrapped = w
    }
}

public extension OpenKeyPath {
    var path: [Any] { wrapped._path }
}

// MARK: Writer Example
public struct Writer {
    var path: any ExtAnyKeyPath
    var value: Any
}

infix operator °= : AssignmentPrecedence

public extension ExtKeyPath {
    static func °=(lhs: Self, rhs: Self.Property) -> Writer {
        return Writer(path: lhs, value: rhs)
    }
}

// MARK: Private Access Management
protocol _ExtAnyKeyPath<Subject> {
    associatedtype Subject
    var _path: [Any] { get }
    init(path: [Any])
}

extension ExtPartialKeyPath: _ExtAnyKeyPath {}
extension ExtKeyPath: _ExtAnyKeyPath {}
extension ExtIndexPath: _ExtAnyKeyPath {}

/*
extension ExtPartialKeyPath {
    public func callAsFunction() -> Self {
        .init(path: _path)
    }
}
extension ExtKeyPath {
    public func callAsFunction() -> Self {
        .init(path: _path)
    }
}
extension ExtIndexPath {
    public func callAsFunction() -> Self {
        .init(path: _path)
    }
}
*/

@dynamicMemberLookup
public struct ExtPartialKeyPath<Subject>: ExtAnyKeyPath {
    public typealias Subject = Subject
    internal let _path: [Any]
    
    init(path: [Any]) {
        self._path = path
    }
    public init() { _path = [] }
}

@dynamicMemberLookup
public struct ExtKeyPath<Subject, Property>: ExtAnyKeyPath {
    public typealias Subject = Subject
    public typealias Property = Property
    
    internal let _path: [Any]
    
    init(path: [Any]) {
        self._path = path
    }
}

public extension ExtKeyPath {
    
    @_disfavoredOverload
    subscript<Value>(dynamicMember key: KeyPath<Property,Value>
    ) -> ExtKeyPath<Subject,Value> {
        .init(path: _path + [key])
    }
    
    subscript<Value>(dynamicMember key: KeyPath<Property,[Value]>
    ) -> ExtIndexPath<Subject,[Value]> {
        .init(path: _path + [key])
    }
}

extension ExtPartialKeyPath {
    
    @_disfavoredOverload
    public subscript<Value>(dynamicMember key: KeyPath<Subject,Value>
    ) -> ExtKeyPath<Subject,Value> {
        .init(path: _path + [key])
    }
    
    public subscript<Value>(dynamicMember key: KeyPath<Subject,[Value]>
    ) -> ExtIndexPath<Subject,[Value]>
    {
        .init(path: _path + [key])
    }
    
}

@dynamicMemberLookup
public struct ExtIndexPath<Subject, Property>: ExtAnyKeyPath {
    public typealias Subject = Subject
    public typealias Property = Property
    
    internal let _path: [Any]
    
    init(path: [Any]) {
        self._path = path
    }
}
extension ExtIndexPath {
    
    @_disfavoredOverload
    public subscript<Value>(dynamicMember key: KeyPath<Property,Value>
    ) -> ExtKeyPath<Subject,Value> {
        .init(path: _path + [key])
    }
    
    public subscript<Value>(dynamicMember key: KeyPath<Subject,[Value]>
    ) -> ExtIndexPath<Subject,[Value]>
    {
        .init(path: _path + [key])
    }
}

extension ExtIndexPath {
    public subscript(_ ndx: Int? = nil) -> ExtKeyPath<Subject,Property> {
        .init(path: _path + [ndx ?? -1])
    }
}

extension ExtIndexPath where Property: Collection {
    public subscript(_ ndx: Int? = nil) -> ExtKeyPath<Subject,Property.Element> {
        .init(path: _path + [ndx ?? -1])
    }
}
