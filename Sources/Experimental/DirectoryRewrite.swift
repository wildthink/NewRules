//
//  DirectoryRewrite.swift
//  NewRules
//
//  Created by Jason Jobe on 8/14/24.
//

import Foundation
import NewRules

struct DirectoryRewrite: Rule {
    
    @Scope(\.template) var template
    var pin: Path
    var pout: Path

    var body: some Rule {
        TraceRule(msg: pin.name)

        ForEach(pin.subs) { p in
//        for p in pin.subs {
            
            let fin  = pin.appending(p)
            let fout = template.rewrite(pin.appending(p))
            let _ = fout.mkdirs()
            
            switch p.uti {
                case .xcodeproj:
                    Xcodeproj(pin: fin, pout: fout)
                        .os_log("Xcode \(fin)")
                case .directory:
                    DirectoryRewrite(pin: fin, pout: fout)
                        .os_log("Directory \(fin)")
                case .text:
                    FileRewrite(pin: fin, pout: fout)
                        .os_log("File \(fin)")
                case .unknown:
                    ErrorRule()
            }
        }
    }
}

struct ErrorRule: Builtin {
    func run(environment: EnvironmentValues) throws {
        // throw error
    }
}

struct Xcodeproj: Builtin {
    var pin: Path
    var pout: Path
    
    func run(environment: EnvironmentValues) throws {
    }
}

struct FileRewrite: Builtin {
//    @Scope(\.template) var template

    var pin: Path
    var pout: Path
    
    func run(environment: EnvironmentValues) throws {
    }
    
//    var body: some Rule {
//        MissingRule()
//    }
}

// MARK: Enviroment Values

//extension EnvironmentValues {
//    @Entry var fileIO = FileIO()
//}

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

// Template
public struct Template: EnvironmentKey {
    public static var defaultValue: Self = .init()

    public func rewrite(_ s: String) -> String {
        s
    }
    
    public func rewrite(_ p: Path) -> Path {
        p
    }
}

extension EnvironmentValues {
    public var template: Template {
        get { self[Template.self] }
        set { self[Template.self] = newValue }
    }
}

// MARK: Rule Modifiers
struct LogModifier: RuleModifier {
    @Scope(\.os_log) var os_log
    var msg: String
    
    func rules(_ content: Content) -> some Rule {
        os_log.debug("\(msg)")
        return content
    }
}
extension Rule {
    func os_log(_ msg: String) -> some Rule {
        self.modifier(LogModifier(msg: msg))
    }
}

struct ChangeDirectory: RuleModifier {
    var pin: Path?
    var pout: Path?
    
    func rules(_ content: Content) -> some Rule {
        content
//            .modifyEnvironment(keyPath: \.fileIO) { io in
//                if let pin { io.pin.append(pin) }
//                if let pout { io.pout.append(pout) }
//            }
    }
}

extension Rule {
    func push(pin: Path? = nil, pout: Path? = nil) -> some Rule {
        self
            .modifier(ChangeDirectory(pin: pin, pout: pout))
    }
}


struct Morph<Content: Rule, Modifier: RuleModifier>: Rule {
    var modifier: Modifier
    @RuleBuilder var content: (Modifier) -> Content
    
    var body: some Rule {
        content(modifier)
    }
}

// MARK: Faux File Interfaces
public enum UTI {
    case xcodeproj
    case directory, text
    case unknown
}

public struct Path: ExpressibleByStringLiteral {
    var name: String = "file"
    var uti: UTI = .unknown
    var subs: [Path] = []
    
    func appending(_ p: Path) -> Path {
        let p = Path(p.name)
//        cp.subs.append(p)
        return p
    }
    
    init(_ name: String, uti: UTI = .unknown, subs: [Path] = []) {
        self.name = name
        self.uti = uti
        self.subs = subs
    }
    
    public init(stringLiteral value: String) {
        name = value
    }
    
    public func mkdirs() -> Path? {
        self
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
