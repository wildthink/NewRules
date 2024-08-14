import XCTest
@testable import NewRules
@testable import Experimental

final class NewRulesTests: XCTestCase {
     
    func testExample() throws {
        let rule = TestRule()
        let env = EnvironmentValues()
        try rule.builtin.run(environment: env)

        print(env)
    }

}

extension Rule {
    func erase() -> some Rule {
        AnyBuiltin(any: self)
    }
}

struct RuleBox<Content: Rule>: Rule {
    @RuleBuilder var content: Content
    
    var body: some Rule {
        content
    }
    
    func trace(_ m: String) -> some Rule {
        print(#function, m)
        return self
    }
}

struct TestRule: Rule {
    enum Opt { case a, b }
    
    let tp: Path = .test
    
    var body: some Rule {
        for p in tp.subs {
            switch p.uti {
                case .directory:
                    TraceRule(msg: p.name)
                case .text:
                    RuleBox {
                        TraceRule(msg: p.name)
                            .modifier(EmptyModifier())
                            .erase()
                    }
                    .trace("okay")
                case .unknown:
                    TraceRule(msg: p.name)
                        .modifier(EmptyModifier())
                        .erase()
             }
        }
    }
}

struct TestRuleII: Rule {
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
    for n in 0..<5 {
        let _ = print(n)
        EmptyRule()
    }
    if true {
        FileRewrite()
    }
    switch opt {
        case .a: EmptyRule()
        case .b: TestRule().modifier(EmptyModifier())
    }
    EmptyRule()
}
