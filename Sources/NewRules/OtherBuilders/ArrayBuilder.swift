//
//  ArrayBuilder.swift
//
//
//  Created by Jason Jobe on 6/13/24.
//

import Foundation

// Inspired by https://gist.github.com/rjchatfield/72629b22fa915f72bfddd96a96c541eb
/// The `ArrayBuilder` is just too handy.
/// ``` swift
/// @ArrayBuilder<String>
/// func foo(flag: Bool) -> [String] {
///     if flag {
///        "TRUE"
///     } else {
///        "FALSE
///     }
/// }
/// ```
///
/// You can also add extenstions for your types to customize the final result
///
/// ``` swift
/// extension ArrayBuilder where Element == String {
///    public static func buildFinalResult(_ component: [Element]) -> String {
///       component.joined(separator: "")
///    }
/// }
///
/// @ArrayBuilder<String> func foo(flag: Bool) -> String {
///    ...
/// }
/// ```
///
@resultBuilder
public struct ArrayBuilder<Element>: EasyBuilder {
    
    public static func transduce(_ e: [[Element]], next: Element? = nil) -> [Element] {
        var b = e.flatMap { $0 }
        if let next {
            b.append(next)
        }
        return b
    }
}

public extension Array {
    init(@ArrayBuilder<Element> _ builder: () -> [Element]) {
        self.init(builder())
    }
}
