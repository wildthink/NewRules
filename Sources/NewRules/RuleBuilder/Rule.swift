import Foundation

public protocol Rule<Body> {
    associatedtype Body: Rule
    @RuleBuilder var body: Body { get }
}

public protocol BuiltinRule {
    func run(environment: ScopeValues) throws
}

public typealias Builtin = BuiltinRule & Rule

public enum RuleError: Error {
    case missing(msg: String, file: String = #file, line: Int = #line)
}

// MARK: Common Rules
public struct AnyBuiltin: Builtin {
    let _run: (ScopeValues) throws -> ()
    
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

    public func run(environment: ScopeValues) throws {
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
    static func buildExpression<N: Rule>(_ expression: N) -> N
    where N.Body == Never {
        expression
    }

    static func buildPartialBlock(first: Never) -> Never {
    }
}

extension Rule {
    public var builtin: BuiltinRule {
        if let x = self as? BuiltinRule { return x }
        return AnyBuiltin(self)
    }
}

public struct EmptyRule: Builtin {
    public init() { }
    public func run(environment: ScopeValues) { }
}

public struct TraceRule: Builtin {
    public typealias Trace = (TraceRule) -> Void
    var msg: String
    var file: String
    var line: Int
    var trace: Trace
    
    public init(msg: String = "TRACE",
                _file: String = #fileID, _line: Int = #line,
                call: Trace? = nil
    ) {
        self.msg = msg
        self.file = _file
        self.line = _line
        self.trace = call ?? { print($0.msg, $0.file, $0.line) }
    }
    
    public func run(environment: ScopeValues) {
        trace(self)
    }
}

public struct Throw: Builtin {
    var error: Error
    
    public init(error: Error) {
        self.error = error
    }
    public func run(environment: ScopeValues) throws {
        throw error
    }
}

extension Optional: Builtin where Wrapped: Rule {
    public func run(environment: ScopeValues) throws {
        try self?.builtin.run(environment: environment)
    }
}

public struct RuleGroup<Content: Rule>: Builtin {
    var content: Content
    
    public init(@RuleBuilder content: () -> Content) {
        self.content = content()
    }
    
    public func run(environment: ScopeValues) throws {
        try content.builtin.run(environment: environment)
    }
}

public struct Pair<L, R>: Builtin where L: Rule, R: Rule {
    var value: (L, R)
    init(_ l: L, _ r: R) {
        self.value = (l,r)
    }
    
    public func run(environment: ScopeValues) throws {
        try value.0.builtin.run(environment: environment)
        try value.1.builtin.run(environment: environment)
    }
}

public enum Choice<L, R>: Builtin where L: Rule, R: Rule {
    case left(L)
    case right(R)

    public func run(environment: ScopeValues) throws {
        switch self {
        case .left(let rule):
            try rule.builtin.run(environment: environment)
        case .right(let rule):
            try rule.builtin.run(environment: environment)
        }
    }
}

extension Array<any Rule>: Builtin {
    public func run(environment: ScopeValues) throws {
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
    
    public func run(environment: ScopeValues) throws {
        try content.builtin.run(environment: environment)
    }
}

// CANNOT USE "-> some Rule" for-loops to work
//   static func buildExpression<R: Rule>(_ expression: R) -> R {
//      expression
//   }
// will work BUT Rule extension modifying method will
// be requied to return a concrete Rule type (i.e. ModifiedRule)
// BUT using `AnyRule` to type erase the Rule at this point/level
// (seems) to make everything build as expected, so no-harm no-foul,
// almost. With AnyRule, you lose the ability to constrain ModifiedContent
// extensions. <sigh>
//   static func buildExpression<R: Rule>(_ expression: R) -> AnyRule {
//      AnyRule(rule: expression)
//   }
// All that said, we provide a ForEach so we don't need buildArray(...)

// MARK: - Rule Builder
@resultBuilder
public enum RuleBuilder {
    
    // MARK: Rule from Expression
    public static func buildExpression<R: Rule>(_ expression: R) -> some Rule {
        expression
    }

    // Optionals
    public static func buildExpression<R: Rule>(_ expression: R?) -> (some Rule)?? {
        expression
    }
    
    // MARK: Rule Building
    public static func buildPartialBlock<R: Rule>(first: R) -> some Rule {
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

// DO NOT USE: Useful for 'for' loops BUT see above NOTE
//    public static func buildArray(_ components: [any Rule]) -> RuleArray {
//        RuleArray(rules: components)
//    }
}
