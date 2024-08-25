//
//  DirectoryRewrite.swift
//  NewRules
//
//  Created by Jason Jobe on 8/14/24.
//

import Foundation
import NewRules

public extension UTType {
    static var pbxproj: UTType =
        UTType(filenameExtension: "pbxproj", conformingTo: .text)!
}

struct DirectoryRewrite: Rule {
    
    @Scope(\.template) var template
    var pin: Path
    var pout: Path

    init?(pin: Path, pout: Path) {
        guard pin.hasDirectoryPath
        else { return nil }
        
        self.pin = pin
        self.pout = pout
    }
    
    func directoryContents() -> [URL] {
        (try? pin.directoryContents()) ?? []
    }
    
    var body: some Rule {

        let rout = template.rewrite(pout.appending(path: pin.lastPathComponent))

        ForEach(directoryContents()) { (fin: URL) in
            
//            let fout = template.rewrite(rout.appending(path: fin.lastPathComponent))
            let fout = rout.appending(path: fin.lastPathComponent)

            switch fin.uti {
//                case _ where fin.isDotFile:
//                    EmptyRule()
                case .pbxproj:
                    TemplateRewrite(pin: fin, pout: fout)
                case .directory:
                    DirectoryRewrite(pin: fin, pout: fout)
                case .text:
                    TemplateRewrite(pin: fin, pout: fout)
                default:
                    TemplateRewrite(pin: fin, pout: fout)
            }
        }
    }
}

func ~= (pattern: UTType?, value: UTType?) -> Bool {
    guard let pattern, let value else { return false }
    return value.conforms(to: pattern)
}

struct ErrorRule: Builtin {
    func run(environment: ScopeValues) throws {
        // throw error
    }
}

struct StencilRewrite: Builtin {
    var pin: Path
    var pout: Path
    
    init(pin: Path, pout: Path) {
        self.pin = pin
        self.pout = pout
    }
    
    func run(environment: ScopeValues) throws {
        let txt = try String(contentsOf: pin)
        let data = environment.template.rewrite(txt).data(using: .utf8)
        let out = environment.template.rewrite(pout)
        out.deletingLastPathComponent().mkdirs()
        try data?.write(to: out)
    }
}

struct TemplateRewrite: Builtin {
    var pin: Path
    var pout: Path
    
    init(pin: Path, pout: Path) {
        self.pin = pin
        self.pout = pout
    }
    
    func run(environment: ScopeValues) throws {
        let txt = try String(contentsOf: pin)
        let data = environment.template.rewrite(txt).data(using: .utf8)
        let out = environment.template.rewrite(pout)
        out.deletingLastPathComponent().mkdirs()
        try data?.write(to: out)
    }
}

struct Copy: Builtin {
    var pin: Path
    var pout: Path
    
    init(pin: Path, pout: Path) {
        self.pin = pin
        self.pout = pout
    }
    
    func run(environment: ScopeValues) throws {
        try FileManager.default.copyItem(at: pin, to: pout)
    }
}

// MARK: Enviroment Values

//extension ScopeValues {
//    @Entry var fileIO = FileIO()
//}

//public struct FileIO: ScopeKey {
//    public static var defaultValue: Self = .init()
//    
//    public var pin: Path = "lhs"
//    public var pout: Path = "rhs"
//}

//extension ScopeValues {
//    public var fileIO: FileIO {
//        get { self[FileIO.self] }
//        set { self[FileIO.self] = newValue }
//    }
//}

// Template
public struct Template: ScopeKey {
    public static var defaultValue: Self = .init()

    public var values: [String: String] = [:]
    
    public func rewrite(_ str: String) -> String {
        str
            .substituteKeys(del: "__", using: values)
            .substituteKeys(del: "--", using: values)
    }
    
    public func rewrite(_ p: Path) -> Path {
        let new = p.filePath
            .substituteKeys(del: "__", using: values)
            .substituteKeys(del: "--", using: values)
        return Path(fileURLWithPath: new)
    }
}

extension ScopeValues {
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

//struct ChangeDirectory: RuleModifier {
//    var pin: Path?
//    var pout: Path?
//    
//    func rules(_ content: Content) -> some Rule {
//        content
////            .modifyEnvironment(keyPath: \.fileIO) { io in
////                if let pin { io.pin.append(pin) }
////                if let pout { io.pout.append(pout) }
////            }
//    }
//}

//extension Rule {
//    func push(pin: Path? = nil, pout: Path? = nil) -> some Rule {
//        self
//            .modifier(ChangeDirectory(pin: pin, pout: pout))
//    }
//}


struct Morph<Content: Rule, Modifier: RuleModifier>: Rule {
    var modifier: Modifier
    @RuleBuilder var content: (Modifier) -> Content
    
    var body: some Rule {
        content(modifier)
    }
}

import UniformTypeIdentifiers
public typealias Path = URL

extension URL {
    
    var isDotFile: Bool {
        filePath.contains("/.")
    }
    
    func mkdirs() {
        try? FileManager.default.createDirectory(at: self, withIntermediateDirectories: true)
    }
    
    func directoryContents() throws -> [URL] {
        try FileManager.default
            .contentsOfDirectory(at: self,
                includingPropertiesForKeys:[.isDirectoryKey, .isPackageKey,
                                            .isRegularFileKey, .contentTypeKey],
                                 options: .skipsHiddenFiles)
    }
    
    var uti: UTType? {
        let rvs = try? self.resourceValues(forKeys: [.contentTypeKey])
        return rvs?.contentType
    }
    
    var filePath: String {
        standardizedFileURL.path
    }
}

extension URL: @retroactive ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = URL(fileURLWithPath: value)
    }
}

public extension String {
    // Xcode templates use delimiters -- and __
    func substituteKeys(del: String, using mapping: [String: String]) -> String {
        let input = self
        var result = input
        let pattern = "\(del)([a-zA-Z0-9_]+)\(del)"
        
        let regex = try! NSRegularExpression(pattern: pattern, options: [])
        let matches = regex.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
        
        let trims = CharacterSet(charactersIn: del)
        for match in matches.reversed() {
            if let range = Range(match.range, in: input) {
                let key = String(input[range]).trimmingCharacters(in: trims)
                if let substitution = mapping[key] {
                    result.replaceSubrange(range, with: substitution)
                }
            }
        }
        return result
    }
}
