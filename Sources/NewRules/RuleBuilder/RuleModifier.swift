public protocol RuleModifier {
    associatedtype Result: Rule
    @RuleBuilder
    func rules(_ content: AnyRule) -> Result
}

public struct AnyRule: Builtin {
    
    private var rule: any Rule

    public init<R: Rule>(rule: R) {
        self.rule = rule
    }

    public func run(environment: ScopeValues) throws {
        try rule.builtin.run(environment: environment)
    }
}
//public typealias AnyRule = Content

public struct ModifiedRule<R: Rule, M: RuleModifier>: Builtin {
    public typealias Content = R
    public typealias Modifier = M
    
    var content: Content
    var modifier: Modifier
    
    public init(content: Content, modifier: Modifier) {
        self.content = content
        self.modifier = modifier
    }
    
    public func run(environment: ScopeValues) throws {
        environment.install(on: modifier)
        try modifier
            .rules(.init(rule: content))
            .builtin.run(environment: environment)
    }
}

//public struct _ModifiedRule<Content: Rule>: Builtin {
//    
//    var content: Content
//    var modifier: any RuleModifier
//    
//    public init(content: Content, modifier: any RuleModifier) {
//        self.content = content
//        self.modifier = modifier
//    }
//    
//    public func run(environment: ScopeValues) throws {
//        environment.install(on: modifier)
//        try modifier
//            .rules(.init(rule: content))
//            .builtin.run(environment: environment)
//    }
//}

extension Rule {
    public func modifier<M: RuleModifier>(_ modifier: M
    ) -> some Rule {
        ModifiedRule(content: self, modifier: modifier)
    }
}

public struct EmptyModifier: RuleModifier {
    public init() {}
    public func rules(_ content: AnyRule) -> some Rule {
        content
    }
}
