//
//  Test.swift
//  NewRules
//
//  Created by Jason Jobe on 7/30/25.
//

import Testing
import Foundation
import Benders

struct Test {
    @Test func testBuilder() async throws {
        let code = 3
        @TypedNodeBuilder
        var bob: some TypedNode {
            MyNode()
            12.45
            Date()
            if true {
                "True"
            } else {
                "Some text"
            }
            switch code {
                case 1: "One"
                case 2: 87.9
                case 3: Date()
                default: "<default>"
            }
            for i in 1...3 {
                "Item \(i)"
            }
        }
        let pp = bob
        print(pp.prettyPrint())
        
        let expanded = pp.expandNode()
        print(expanded.prettyPrint())
    }
    
    @Test func testRuleBuilder() async throws {
        let code = 3
        @RuleBuilder
        var bob: some Rule {
            12.45
            Date()
            if true {
                "Single line if"
            }
            if true {
                "True"
            } else {
                "Some text"
            }
            switch code {
                case 1: "One"
                case 2: 87.9
                case 3: Date()
                default: "<default>"
            }
            for i in 1...3 {
                "Item \(i)"
            }
        }
        let pp = bob.prettyPrint()
//        let rule: some Rule = AnyRule(value: "hey")
//        let mr = rule.modifiedRule()
//        print(#line, rule, mr)
        print(pp)
        print("FIN", #function)
    }
}

extension Rule where Self == AnyRule {
    @RuleBuilder
    func modifiedRule() -> some Rule {
        GroupRule(self)
    }
}

extension Rule {
    @RuleBuilder
    func modifiedRule() -> some Rule {
        self
    }
}

struct MyNode: TypedNode {
    var body: some TypedNode {
        "My basic body"
    }
}

// MARK: LOCAL RuleBuilder
public protocol Rule<Body> {
    associatedtype Body: Rule = Never
    @RuleBuilder var body: Body { get }
}

public struct EmptyRule: Rule {}
extension Never: Rule {}
extension Rule where Body == Never {
    public var body: Never {
        fatalError("init(body:) has not been implemented")
    }
}

public struct GroupRule: Rule {
    var children: [any Rule]
    init(_ children: (any Rule)...) {
        self.children = children
    }
    init(_ children: [any Rule]) {
        self.children = children
    }

}

public protocol LiteralRule: Rule {}
extension Optional: Rule where Wrapped: Rule {}

public struct AnyRule: Rule {
    var value: Any?
}

// MARK: Literal Rules
// NOTE: Good or Bad Idea?
extension Double: LiteralRule {}
extension Date: LiteralRule {}
extension String: LiteralRule {}

extension RuleBuilder {
    public static func buildExpression<A>(_ expression: A) -> some Rule {
        AnyRule(value: expression)
    }
}

@resultBuilder
public enum RuleBuilder {
    
    public static func buildBlock<each Content: Rule>(_ rules: repeat each Content) -> GroupRule {
        var av: [any Rule] = []
        for rule in repeat (each rules) {
            av.append(rule)
        }
        return GroupRule(av)
    }
    
    // MARK: Rule from Expression
    public static func buildExpression<R: Rule>(_ exp: R) -> some Rule {
        exp
    }
    
    // Optionals - Do we also need "-> (some Rule)??
    public static func buildExpression<R: Rule>(_ exp: R?) -> (some Rule)? {
        exp
    }

    // Empty Rule
    public static func buildRule() -> some Rule { Optional<EmptyRule>.none }
    
    // Empty partial Rule. Useful for switch cases to represent no Rules.
    public static func buildPartialBlock(first: Void) -> some Rule {
        Optional<EmptyRule>.none
    }
    
    // Rule for an 'if' condition.
    public static func buildIf<Content>(_ content: Content?
    ) -> Content? where Content : Rule {
        content
    }
    
    // Rule for an 'if' condition which also have an 'else' branch.
    public static func buildEither<R: Rule>(first rule: R) -> R {
        rule
    }
    
    // Rule for the 'else' branch of an 'if' condition.
    public static func buildEither<R: Rule>(second rule: R) -> R {
        rule
    }
    
    // DO NOT USE: Useful for 'for' loops BUT see above NOTE
//    public static func buildArray(_ components: [any Rule]) -> GroupRule {
//        GroupRule(components.compactMap(\.self))
//    }
    public static func buildArray(_ components: [any Rule]) -> GroupRule {
        GroupRule(components.compactMap(\.self))
    }

}

extension [any Rule]: Rule {}

// MARK: Pretty Print
public extension Rule {
    func prettyPrint(indent: String = "", isLast: Bool = true) -> String {
        if let group = self as? GroupRule {
            group.prettyPrint(indent: indent, isLast: isLast)
        } else if let seq = self as? (any Collection<any Rule>) {
            seq.prettyPrint(indent: indent, isLast: isLast)
        } else if let lit = self as? any LiteralRule {
            lit.prettyPrint(indent: indent, isLast: isLast)
        } else {
            ""
        }
    }
}

public extension Collection where Element == any Rule {
    func prettyPrint(indent: String = "", isLast: Bool = true) -> String {
        let branch = isLast ? "└── " : "├── "
        var result = indent + branch
        
        result += "Collection\n"
        let newIndent = indent + (isLast ? "    " : "│   ")
        for (index, child) in self.enumerated() {
            let last = index == self.count - 1
            result += child.prettyPrint(indent: newIndent, isLast: last)
        }
        return result
    }
}

public extension GroupRule {
    func prettyPrint(indent: String = "", isLast: Bool = true) -> String {
        let branch = isLast ? "└── " : "├── "
        var result = indent + branch
        
        result += "List\n"
        let newIndent = indent + (isLast ? "    " : "│   ")
        for (index, child) in children.enumerated() {
            let last = index == children.count - 1
            result += child.prettyPrint(indent: newIndent, isLast: last)
        }
        return result
    }
}
public extension LiteralRule {
    func prettyPrint(indent: String = "", isLast: Bool = true) -> String {
        let branch = isLast ? "└── " : "├── "
        var result = indent + branch
        result += String(describing: self)
        result += "\n"
        return result
    }
}

//#if PRINT
public extension Rule where Body == Never {
    func prettyPrint(indent: String = "", isLast: Bool = true) -> String {
        ""
    }
}

//#endif

// func resolve(in: Scope) -> some Rule
//public extension Rule {
//    func expandNode() -> any Rule {
//        expandNode(self)
//    }
//    
//    func expandNode(_ node: some Rule) -> Rule {
//        if let anyNode = node as? AnyTypedNode {
//            return anyNode
//        }
//        let body = node.body
//        if let anyBody = body as? AnyTypedNode {
//            return anyBody
//        }
//        // Recursively expand body
//        return expandNode(body)
//    }
//}
