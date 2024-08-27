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
        let fin: URL = "/Users/jason/dev/Constellation/templates/mac/DocumentApp"
        let output: URL = "/tmp/Demo"
        
        // FOR TEST Purposes ONLY
        try FileManager.default.removeItem(at: output)
        
        let rule =
        DirectoryRewrite(in: fin, out: output)
            .template(merge: [
                "APP": "Demo",
                "NOW": Date().formatted(date: .abbreviated, time: .shortened),
            ])
            .template(set: "COPYRIGHT", to: "See project License")

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
}

extension Rule {
    
    @warn_unqualified_access
    func template<S: CustomStringConvertible>(
        set key: String, to value: S
    ) -> some Rule {
        modifyEnvironment(keyPath: \.template) {
            $0.values[key] = value.description
        }
    }

    @warn_unqualified_access
    func template(merge: [String:CustomStringConvertible]) -> some Rule {
        modifyEnvironment(keyPath: \.template) {
            let values = merge.map { ($0.key, $0.value.description) }
            $0.values.merge(values, uniquingKeysWith: { $1 })
        }
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
