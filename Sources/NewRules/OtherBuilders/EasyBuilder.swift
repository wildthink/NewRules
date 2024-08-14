//
//  ArrayBuilder 2.swift
//  Carbon
//
//  Created by Jason Jobe on 8/5/24.
//


//
//  ArrayBuilder.swift
//
//
//  Created by Jason Jobe on 6/13/24.
//

import Foundation

// Inspired by https://gist.github.com/rjchatfield/72629b22fa915f72bfddd96a96c541eb
/** The `ArrayBuilder` is just too handy.
``` swift
@resultBuilder
struct ArrayBuilder<Element>: EasyBuilder {
    
    static func transduce(_ e: [[Element]], next: Element? = nil) -> [Element] {
        var b = e.flatMap { $0 }
        if let next {
            b.append(next)
        }
        return b
    }
}
```
 */
///
/// You can also add extenstions for your types to customize the final result
///
/// ``` swift
/// extension ArrayBuilder where Element == String {
///    static func buildFinalResult(_ component: Block) -> String {
///       component.joined(separator: "")
///    }
/// }
///
/// @ArrayBuilder<String> func foo(flag: Bool) -> String {
///    ...
/// }
/// ```
///

public protocol EasyBuilder<Element, Block> {
    associatedtype Element
    associatedtype Block
    static func transduce(_ e: [Block], next: Element?) -> Block
}

public extension EasyBuilder {
    static func buildFinalResult(_ component: Block) -> Block {
        component
    }
}

public extension EasyBuilder {
    static func transduce(_ e: Element?) -> Block {
        transduce([], next: e)
    }
    
    static func transduce(_ e: Block?, next: Element? = nil) -> Block {
        if let e {
            return transduce([e], next: next)
        } else {
            return transduce([], next: next)
        }
    }

    // MARK: Block from Expression
    static func buildExpression(_ expression: Element) -> Block {
        transduce(expression)
    }
    
    static func buildExpression(_ expression: Block) -> Block {
        return expression
    }
    
    // Optionals
    static func buildExpression(_ expression: Element?) -> Block {
        transduce(expression)
    }
    
    static func buildExpression(_ expression: Block?) -> Block {
        transduce(expression)
    }

    // MARK: Block Building
    static func buildPartialBlock(first: Element) -> Block { transduce(first) }
    static func buildPartialBlock(first: Block) -> Block { transduce(first) }
    
    static func buildPartialBlock(accumulated: Block, next: Element) -> Block { transduce(accumulated, next: next) }
    @_disfavoredOverload
    static func buildPartialBlock(accumulated: Block, next: Block) -> Block { transduce([accumulated, next], next: nil) }
    
    // Empty block
    static func buildBlock() -> Block { transduce(Optional<Block>.none) }
    
    // Empty partial block. Useful for switch cases to represent no elements.
    static func buildPartialBlock(first: Void) -> Block { transduce(Optional<Block>.none) }
        
    // Block for an 'if' condition.
    static func buildIf(_ element: Block?) -> Block { transduce(element) }
    
    // Block for an 'if' condition which also have an 'else' branch.
    static func buildEither(first: Block) -> Block { first }
    
    // Block for the 'else' branch of an 'if' condition.
    static func buildEither(second: Block) -> Block { second }
    
    // Block for an array of elements. Useful for 'for' loops.
    static func buildArray(_ components: [Block]) -> Block { transduce(components, next: nil) }
}

extension EasyBuilder {
    // Impossible partial block. Useful for fatalError().
    static func buildPartialBlock(first: Never) -> Block {}
}
