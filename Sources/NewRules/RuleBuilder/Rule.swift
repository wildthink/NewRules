import Foundation

public protocol BuiltinRule {
    func run(environment: EnvironmentValues) throws
}

public typealias Builtin = BuiltinRule & Rule

public struct AnyBuiltin: Builtin {
    let _run: (EnvironmentValues) throws -> ()
    
    public init<R: Rule>(_ value: R) {
        self._run = { env in
            env.install(on: value)
            try value.body.builtin.run(environment: env)
        }
    }

    public init(any value: any Rule) {
        if let b = value as? any Builtin {
            self._run = { try b.run(environment: $0) }
        } else {
            self._run = { env in
                env.install(on: value)
                try value.body.builtin.run(environment: env)
            }
        }
    }

    public func run(environment: EnvironmentValues) throws {
        try _run(environment)
    }
}

public extension BuiltinRule {
    typealias Body = Never
    var body: Never {
        fatalError("NEVER")
    }
}

extension Rule where Body == Never {
    func run() { fatalError() }
}

extension Never: Rule {
    public typealias Body = Never
    public var body: Never { fatalError("NEVER") }
}

extension RuleBuilder {
    // Impossible partial Rule. Useful for fatalError().
    // static func buildExpression(_ expression: any Rule) -> Never
    static func buildPartialBlock(first: Never) -> Never {
    }
}

public protocol Rule<Body> {
    associatedtype Body: Rule
    @RuleBuilder var body: Body { get }
}

extension Rule {
    public var builtin: BuiltinRule {
        if let x = self as? BuiltinRule { return x }
        return AnyBuiltin(self)
    }
}

public struct EmptyRule: Builtin {
    public init() { }
    public func run(environment: EnvironmentValues) { }
}

public struct TraceRule: Builtin {
    var msg: String
    var file: String
    var line: Int
    
    init(msg: String = "TRACE", file: String = #fileID, line: Int = #line) {
        self.msg = msg
        self.file = file
        self.line = line
    }
    
    public func run(environment: EnvironmentValues) {
        print(msg, file, line)
    }
}

public struct MissingRule: BuiltinRule, Rule {
    var file: String
    var line: Int
    
    public init(file: String = #fileID, line: Int = #line) {
        self.file = file
        self.line = line
    }
    
    public var errorDescription: String {
        "\(file):\(line)"
    }
    
    public func run(environment: EnvironmentValues) throws {
        throw RuleError.missing(errorDescription)
    }
}

public enum RuleError: Error {
    case missing(String)
}

extension Optional: Builtin where Wrapped: Rule {
    public func run(environment: EnvironmentValues) throws {
        try self?.builtin.run(environment: environment)
    }
}

public struct RuleGroup<Content: Rule>: Builtin {
    var content: Content
    
    public init(@RuleBuilder content: () -> Content) {
        self.content = content()
    }
    
    public func run(environment: EnvironmentValues) throws {
        try content.builtin.run(environment: environment)
    }
}

public struct Pair<L, R>: Builtin where L: Rule, R: Rule {
    var value: (L, R)
    init(_ l: L, _ r: R) {
        self.value = (l,r)
    }
    
    public func run(environment: EnvironmentValues) throws {
        try value.0.builtin.run(environment: environment)
        try value.1.builtin.run(environment: environment)
    }
}

public enum Choice<L, R>: Builtin where L: Rule, R: Rule {
    case left(L)
    case right(R)

    public func run(environment: EnvironmentValues) throws {
        switch self {
        case .left(let rule):
            try rule.builtin.run(environment: environment)
        case .right(let rule):
            try rule.builtin.run(environment: environment)
        }
    }
}

extension Array<any Rule>: Builtin {
    public func run(environment: EnvironmentValues) throws {
        for rule in self {
            try rule.builtin.run(environment: environment)
        }
    }
}

public struct RuleArray: Builtin {
    var content: [any Rule]
    
    public init(rules: [any Rule]) {
        self.content = rules
    }
    
    public func run(environment: EnvironmentValues) throws {
        try content.builtin.run(environment: environment)
    }
}

struct TestRule: Rule {
    var opt: Opts = .a
    
    var body: some Rule {
        EmptyRule()
        for n in 0..<5 {
            let _ = print(n)
            EmptyRule()
        }
        if true {
            FileRewrite()
        } else {
            branch("b1")
        }
        switch opt {
            case .a: EmptyRule()
            case .b: TestRule().modifier(EmptyModifier())
        }
        EmptyRule()
    }
    
    @RuleBuilder
    func branch(_ p: Path) -> some Rule {
        switch p.uti {
            case .directory:
                DirectoryRewrite()
            case .text:
                FileRewrite()
            case .unknown:
                EmptyRule()
        }
    }

}

enum Opts { case a, b }
@RuleBuilder
func sampler(opt: Opts) -> some Rule {
    EmptyRule()
//    for n in 0..<5 {
//        let _ = print(n)
//        EmptyRule()
//    }
//    if true {
//        FileRewrite()
//    }
    switch opt {
        case .a: EmptyRule()
        case .b: TestRule().modifier(EmptyModifier())
    }
    EmptyRule()
}

@resultBuilder
public enum RuleBuilder {
    
    // MARK: Rule from Expression
    // CANNOT USE "-> some Rule" for loops to work
    public static func buildExpression<R: Rule>(_ expression: R) -> R {
        return expression
    }

//    public static func buildExpression(_ expression: ModifiedRule) -> ModifiedRule {
//        return expression
//    }

    @_disfavoredOverload
    public static func buildExpression<R: Rule>(_ expression: R) -> some Rule {
        return expression
    }

    // Optionals
    public static func buildExpression<R: Rule>(_ expression: R?) -> R? {
        expression
    }
    
    // MARK: Rule Building
    public static func buildPartialBlock<R: Rule>(first: R) -> R {
        first
    }
    public static func buildPartialBlock<R1: Rule, R2: Rule>(
        accumulated: R1, next: R2
    ) -> some Rule {
        Pair(accumulated, next)
    }
     
    // Empty Rule
    public static func buildRule() -> some Rule { Optional<EmptyRule>.none }
    
    // Empty partial Rule. Useful for switch cases to represent no Rules.
    public static func buildPartialBlock(first: Void) -> some Rule { Optional<EmptyRule>.none }
        
    // Rule for an 'if' condition.
    public static func buildIf<Content>(_ content: Content?) -> Content? where Content : Rule {
        content
    }

    // Rule for an 'if' condition which also have an 'else' branch.
    public static func buildEither<L, R>(first component: L) -> Choice<L, R> {
        .left(component)
    }

    // Rule for the 'else' branch of an 'if' condition.
    public static func buildEither<L, R>(second component: R) -> Choice<L, R> {
        .right(component)
    }

    // Rule for an array of Rules. Useful for 'for' loops.
    public static func buildArray(_ components: [any Rule]) -> RuleArray {
        RuleArray(rules: components)
    }
}
