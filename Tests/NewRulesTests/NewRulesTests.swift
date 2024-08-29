import XCTest
@testable import NewRules
@testable import Rewriter

final class NewRulesTests: XCTestCase {
     
    func testClone() async throws {
        let base: URL = "~/dev/constellation/mac"
        let output: URL = "/tmp/Clone_i"
        
        let context: [String: CustomStringConvertible] = [
            "APP": "Demo",
            "NOW": someDate,
            "COPYRIGHT": "See project License",
        ]
        
        @RuleBuilder
        var script: some Rule {
//            RuleGroup {
                Rewrite(in: base/"MacApp", out: output)
                Rewrite(in: base/"packs/DocAppPack", out: output)
                    .template(mode: .overwrite)
//            }
//            .template(merge: context)
        }
        
        // FOR TEST Purposes ONLY
        try? FileManager.default.removeItem(at: output)
        try script.template(merge: context).run()
    }
    
    let someDate = Date(timeIntervalSince1970: 0)
        .formatted(date: .abbreviated, time: .shortened)

    func testExample() throws {
        let rule = TestRule()
        let env = ScopeValues()
        try rule.builtin.run(environment: env)

        print(env)
    }
    
    func testDirectoryIterator() throws {
        let url: URL = "/tmp"
        
        guard let seq = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey, .isRegularFileKey, .contentTypeKey])
        else { return }
        for s in seq {
            if let u = s as? URL {
                print(u, u.isFileURL, u.hasDirectoryPath, u.uti as Any)
            } else {
                print(type(of: s), s)
            }
        }
    }
    
    func testURLAddtions() {
        let base: URL = "~/dev"
        print(#line, base)
        print(#line, base.standardized)
        print(#line, base.standardizedFileURL)

        print(#line, base.filePath)

        print(#line, base/"//constellation")
        print(#line, base/"//constellation/mac")
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

extension RuleBuilder {
    static func buildExpression(_ expression: TestRule.Opt) -> some Rule {
        EmptyRule()
    }
}

struct TestRule: Rule {
    enum Opt { case a, b }
    
    let tp: URL = "https://example.com"
    
    func foo() -> some Rule {
        self.emptyModifier()
    }
    
    func v(_ o: Opt) -> Opt { o }
    
    @RuleBuilder
    func bar() -> some Rule {
        EmptyRule()
        v(.a)
        v(.b)
        EmptyRule()
    }
    
    func directoryContents() -> [URL] {
        (try? tp.directoryContents()) ?? []
    }
    
    var body: some Rule {
        ForEach(directoryContents()) { p in
            switch p.uti {
                case .directory:
                    TraceRule(msg: p.filePath)
                        .modifier(EmptyModifier())
                       .erase()
                case .text:
                    RuleBox {
                        TraceRule(msg: p.filePath)
                            .modifier(EmptyModifier())
                            .erase()
                    }
                    .trace("okay")
                default:
                    TraceRule(msg: p.filePath)
                        .emptyModifier()
             }
        }
    }
}
