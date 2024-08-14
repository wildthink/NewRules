import Foundation

extension Rule {
    func tbd() -> some Rule {
        EmptyRule()
    }
    
    @RuleBuilder
    func xmod() -> some Rule {
//        self
        DirectoryRewrite()
//        ModifiedRule(content: EmptyRule(), modifier: EmptyModifier())
    }
}

struct Morph<Content: Rule, Modifier: RuleModifier>: Rule {
    var modifier: Modifier
    @RuleBuilder var content: (Modifier) -> Content
    
    var body: some Rule {
        content(modifier)
    }
}
//extension Rule {
//    func morph<Content: Rule, Modifier: RuleModifier>(_ m: Modifier) -> Content {
//        Morph {
//            
//        }
//    }
//}

public enum UTI {
    case directory, text
    case unknown
}

public struct Template {
    public func rewrite(_ s: String) -> String {
        s
    }
    
    public func rewrite(_ p: Path) -> Path {
        p
    }

}

public struct Path: ExpressibleByStringLiteral {
    var name: String = "file"
    var uti: UTI = .unknown
    var subs: [Path] = []
    mutating func append(_ p: Path) {
        subs.append(p)
    }
    
    init(_ name: String, uti: UTI = .unknown, subs: [Path] = []) {
        self.name = name
        self.uti = uti
        self.subs = subs
    }
    
    public init(stringLiteral value: String) {
        name = value
    }
}

extension Path {
    static var test: Path =
        Path("test", subs: [
            Path("dir", uti: .directory),
            Path("text", uti: .text),
            Path("joker", uti: .unknown),
        ])
}

public struct FileIO: EnvironmentKey {
    public static var defaultValue: Self = .init()
    
    public var pin: Path = "lhs"
    public var pout: Path = "rhs"
}

extension EnvironmentValues {
    public var fileIO: FileIO {
        get { self[FileIO.self] }
        set { self[FileIO.self] = newValue }
    }
}

struct ChangeDirectory: RuleModifier {
    var pin: Path?
    var pout: Path?
    
    func rules(_ content: Content) -> some Rule {
        content
            .modifyEnvironment(keyPath: \.fileIO) { io in
                if let pin { io.pin.append(pin) }
                if let pout { io.pout.append(pout) }
            }
    }
}
extension Rule {
    func push(pin: Path? = nil, pout: Path? = nil) -> ModifiedRule {
        self
            .modifier(ChangeDirectory(pin: pin, pout: pout))
    }
}

extension Rule {
    func typeErase() -> AnyBuiltin {
        AnyBuiltin(self)
    }
}

struct DirectoryRewrite: Rule {
    
    @Environment(\.fileIO) var io
    var template: Template = .init()
    
    func rewrite(_ p: Path) -> Path {
        // __FILE__.swift -> p.swift
        p
    }
    
    @RuleBuilder
    func branch(_ p: Path) -> some Rule {
        switch p.uti {
            case .directory:
                Morph(modifier: EmptyModifier()) { m in
                    DirectoryRewrite()
                        .modifier(m)
                        .push(pin: p, pout: template.rewrite(p))
                }
            case .text:
                FileRewrite()
                    .modifyEnvironment(keyPath: \.fileIO) { _ in }
            case .unknown:
                EmptyRule()
        }
    }
    
    @RuleBuilder
    func branch_ii(_ p: Path) -> some Rule {
        if p.uti == .directory {
            Morph(modifier: EmptyModifier()) { m in
                DirectoryRewrite()
                    .modifier(m)
                    .push(pin: p, pout: template.rewrite(p))
            }
        } else if p.uti == .text {
            FileRewrite()
                .modifyEnvironment(keyPath: \.fileIO) { _ in }
        } else {
            EmptyRule()
        }
    }

    let tp: Path = .test
    
    var body: some Rule {
        
//        if true {
//            FileRewrite()
//                .modifyEnvironment(keyPath: \.fileIO) { _ in }
//        }
//        
//        branch_ii(.init())

        for p in tp.subs {
//            branch_ii(p)
            TraceRule(msg: p.name)
        }
    }
}

struct FileRewrite: Rule {
    
    var pin: Path = "lhs_file"
    var pout: Path = "rhs_file"
    
    var body: some Rule {
        xmod()
        tbd()
    }
}
