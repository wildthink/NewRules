import XCTest
@testable import NewRules

final class NewRulesTests: XCTestCase {
     
    func testExample() throws {
//        let d1 = DirectoryRewrite()
        let d2 =
        TestRule()
//            .push(pin: .init(), pout: .init())
        
//        let r1 = try d1.builtin.run(environment: EnvironmentValues())
        let env = EnvironmentValues()
        try d2.builtin.run(environment: env)

        print(type(of: d2), env)
    }

}

extension Rule {
    func erase() -> some Rule {
        AnyBuiltin(any: self)
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
                    TraceRule(msg: p.name)
                case .unknown:
                    TraceRule(msg: p.name)
                        .modifier(EmptyModifier())
                        .erase()
             }
        }
    }
}

extension RuleBuilder {
//    @_disfavoredOverload/
    public static func buildExpression(_ expression: any Rule) -> AnyBuiltin {
        AnyBuiltin(any: expression)
    }
}
