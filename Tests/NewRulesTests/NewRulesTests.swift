import XCTest
@testable import NewRules
@testable import Experimental

final class NewRulesTests: XCTestCase {
     
    func testExample() throws {
        let rule = TestRule()
        let env = ScopeValues()
        try rule.builtin.run(environment: env)

        print(env)
    }

    func testRewriter() throws {
        let rule = DirectoryRewrite(pin: "/Users/jason/dev/templates/AppUX/", pout: "/tmp")
        let env = ScopeValues()
        try rule.builtin.run(environment: env)
        
        print(env)
    }
}

extension Rule {
    @warn_unqualified_access
    func erase() -> some Rule {
        AnyRule(rule: self)
    }
    
    @warn_unqualified_access
    func emptyModifier() -> some Rule {
        self.modifier(EmptyModifier())
    }
}

struct RuleBox<Content: Rule>: Rule {
    @RuleBuilder var content: Content
    
    var body: some Rule {
        content
    }
    
    func trace(_ m: String) -> Self {
        print(#function, m)
        return self
    }
}

struct TestRule: Rule {
    enum Opt { case a, b }
    
    let tp: Path = .test
    
    func foo() -> some Rule {
        self.emptyModifier()
    }
    
    var body: some Rule {
        ForEach(tp.subs) { p in
            switch p.uti {
                case .xcodeproj:
                    TraceRule(msg: p.name)
                case .directory:
                    TraceRule(msg: p.name)
                        .modifier(EmptyModifier())
                       .erase()
                case .text:
                    RuleBox {
                        TraceRule(msg: p.name)
                            .modifier(EmptyModifier())
                            .erase()
                    }
                    .trace("okay")
                case .unknown:
                    TraceRule(msg: p.name)
                        .emptyModifier()
             }
        }
    }
}

//struct TestRuleII: Rule {
//    var opt: Opts = .a
//    
//    var body: some Rule {
//        EmptyRule()
//        for n in 0..<5 {
//            let _ = print(n)
//            EmptyRule()
//        }
//        if true {
//            FileRewrite()
//        } else {
//            branch("b1")
//        }
//        switch opt {
//            case .a: EmptyRule()
//            case .b: TestRule().modifier(EmptyModifier())
//        }
//        EmptyRule()
//    }
//    
//    @RuleBuilder
//    func branch(_ p: Path) -> some Rule {
//        switch p.uti {
//            case .directory:
//                DirectoryRewrite()
//            case .text:
//                FileRewrite()
//            case .unknown:
//                EmptyRule()
//        }
//    }
//    
//}

enum Opts { case a, b }
//@RuleBuilder
//func sampler(opt: Opts) -> some Rule {
//    EmptyRule()
//    for n in 0..<5 {
//        let _ = print(n)
//        EmptyRule()
//    }
//    if true {
//        FileRewrite()
//    }
//    switch opt {
//        case .a: EmptyRule()
//        case .b: TestRule().modifier(EmptyModifier())
//    }
//    EmptyRule()
//}
