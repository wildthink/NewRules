//
//  TypedNode.swift
//  NewRules
//
//  Created by Jason Jobe on 7/30/25.
//

public protocol TypedNode {
    associatedtype Body: TypedNode = Never
    @TypedNodeBuilder
    var body: Body { get }
}

public extension TypedNode where Body == Never {
    var body: Never { fatalError("Leaf node has no body") }
}

extension Never: TypedNode {}

public struct ATNode<T>: TypedNode {
    var value: T
}

public struct AnyTypedNode: TypedNode {
    var node: any TypedNode
}

public struct GroupNode: TypedNode {
    var children: [AnyTypedNode]
}

@resultBuilder
public struct TypedNodeBuilder {
    public static func buildBlock(_ components: AnyTypedNode...) -> AnyTypedNode {
        AnyTypedNode(node: GroupNode(children: components))
    }
}

public extension TypedNodeBuilder {
    typealias Element = AnyTypedNode
    static func buildExpression<T>(_ value: T) -> AnyTypedNode {
        AnyTypedNode(node: ATNode(value: value))
    }
    static func buildOptional(_ component: AnyTypedNode?) -> AnyTypedNode {
        component ?? AnyTypedNode(node: GroupNode(children: []))
    }
    static func buildEither(first component: AnyTypedNode) -> AnyTypedNode { component }
    static func buildEither(second component: AnyTypedNode) -> AnyTypedNode { component }
    static func buildArray(_ components: [AnyTypedNode]) -> AnyTypedNode {
        AnyTypedNode(node: GroupNode(children: components))
    }
}

// ANSI color constants
public struct ANSIColors {
    public let blue = "\u{001B}[34m"
    public let green = "\u{001B}[32m"
    public let magenta = "\u{001B}[35m"
    public let reset = "\u{001B}[0m"
}

public struct NoColors {
    public let blue = ""
    public let green = ""
    public let magenta = ""
    public let reset = ""
}

// Extension for pretty printing AnyTypedNode as a tree
public extension TypedNode {
    func prettyPrint(indent: String = "", isLast: Bool = true) -> String {
        (self as? AnyTypedNode)?.prettyPrint() ?? ""
    }
}

public extension TypedNode where Body == Never {
    func prettyPrint(indent: String = "", isLast: Bool = true) -> String {
        ""
    }
}

public extension AnyTypedNode {
    func prettyPrint(indent: String = "", isLast: Bool = true) -> String {
        let colors = NoColors()
        let branch = isLast ? "└── " : "├── "
        var result = indent + branch
        switch node {
            case let group as GroupNode:
                result += "\(colors.blue)GroupNode\(colors.reset)\n"
                let newIndent = indent + (isLast ? "    " : "│   ")
                for (index, child) in group.children.enumerated() {
                    let last = index == group.children.count - 1
                    result += child.prettyPrint(indent: newIndent, isLast: last)
                }
            case let leaf as ATNode<Any>:
                result += "\(colors.green)ATNode(value: \(leaf.value))\(colors.reset)\n"
            case is MyNode:
                result += "\(colors.magenta)MyNode\(colors.reset)\n"
            default:
                // Handle generic ATNode without knowing type
                if let mirrorValue = Mirror(reflecting: node).children.first?.value {
                    result += "\(colors.green)ATNode(value: \(mirrorValue))\(colors.reset)\n"
                } else {
                    result += "\(type(of: node))\n"
                }
        }
        return result
    }
}

public extension TypedNode {
    func expandNode() -> AnyTypedNode {
        expandNode(self)
    }
    
    func expandNode(_ node: some TypedNode) -> AnyTypedNode {
        if let anyNode = node as? AnyTypedNode {
            return anyNode
        }
        let body = node.body
        if let anyBody = body as? AnyTypedNode {
            return anyBody
        }
        // Recursively expand body
        return expandNode(body)
    }
}

// MARK: Test code
/*
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
}
*/
