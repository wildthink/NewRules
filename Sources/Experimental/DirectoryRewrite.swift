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
        guard pin.hasDirectoryPath, pout.hasDirectoryPath
        else { return nil }
        
        self.pin = pin
        self.pout = pout
    }
    
    func directoryContents() -> [URL] {
        (pin.directoryContents()?.allObjects as? [URL]) ?? []
    }
    
    var body: some Rule {
//        TraceRule(msg: pin.filePath)

        ForEach(directoryContents()) { (fin: URL) in
            
            let fout = template.rewrite(pout.appending(path: fin.lastPathComponent))
            let _ = fout.mkdirs()
            
            switch fin.uti {
                case .pbxproj:
                    TemplateRewrite(pin: fin, pout: fout)
//                        .os_log("Xcode project.pbxproj \(fin)")
                case .directory:
                    DirectoryRewrite(pin: fin, pout: fout)
//                        .os_log("Directory \(fin)")
                case .text:
                    StencilRewrite(pin: fin, pout: fout)
//                        .os_log("File \(fin)")
                default:
                    EmptyRule()
                        .os_log("Unknown \(fin.uti)")
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
        try FileManager.default.copyItem(at: pin, to: pout)
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
        try FileManager.default.copyItem(at: pin, to: pout)
    }
}

// MARK: Enviroment Values

//extension ScopeValues {
//    @Entry var fileIO = FileIO()
//}

public struct FileIO: ScopeKey {
    public static var defaultValue: Self = .init()
    
    public var pin: Path = "lhs"
    public var pout: Path = "rhs"
}

extension ScopeValues {
    public var fileIO: FileIO {
        get { self[FileIO.self] }
        set { self[FileIO.self] = newValue }
    }
}

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
//        let list =
//        p.subs.map {
//            $0.substituteKeys(del: "__", using: values)
//                .substituteKeys(del: "--", using: values)
//        }
//        return Path(subs: list)
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
//public enum UTI {
//    case pbxproj // project.pbxproj
//    case directory, text
//    case unknown
//}

//extension FileManager {
//    
//    func uti(for file: String) -> UTI {
//        var isDir: ObjCBool
//        self.fileExists(atPath: file, isDirectory: &isDir)
//        if isDir.boolValue { return .directory }
//        if (file as NSString).pathExtension == "pbxproj" {
//            return .pbxproj
//        }
//        // else
//        return .text
//    }
//}

//class DirectoryFiles: Sequence {
//    typealias Element = URL
//    private var root: URL
//    
//    init() { }
//    init(_ root: URL) {
//        self.root = root
//    }
//    
//    func makeIterator() -> AnyIterator<URL> {
//        // We establish the index *outside* the
//        // closure. More below.
//        var index = self.backingStore.startIndex
//        // Note the use of AnyIterator.init(:) with
//        // trailing closure syntax.
//        return AnyIterator { () -> Int? in
//            // Is the current index before the end?
//            if index < self.backingStore.endIndex {
//                // If so, get the current value
//                let currentValue = self.backingStore[index]
//                // Set a new index for the next execution
//                index = self.backingStore.index(after: index)
//                // Return the current value
//                return currentValue
//            } else {
//                // We've run off the end of the array, return nil.
//                return nil
//            }
//        }
//    }
//}

import UniformTypeIdentifiers
public typealias Path = URL

//extension URL: @retroactive ExpressibleByExtendedGraphemeClusterLiteral {}
//extension URL: @retroactive ExpressibleByUnicodeScalarLiteral {}

extension URL {
    
    func mkdirs() {
        try? FileManager.default.createDirectory(at: self, withIntermediateDirectories: true)
    }
    
    func directoryContents() -> FileManager.DirectoryEnumerator? {
        FileManager.default
            .enumerator(at: self,
                        includingPropertiesForKeys:
                            [.isDirectoryKey, .isPackageKey,
                             .isRegularFileKey, .contentTypeKey])
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

//public struct Path: ExpressibleByStringLiteral {
//    var subs: [String] = []
//    var filePath: String { subs.joined(separator: "/") }
//    var uti: UTI { FileManager.default.uti(for: filePath) }
//
//    init(subs: [String] = []) {
//        self.subs = subs
//    }
//    
//    public init(stringLiteral value: String) {
//        subs = value.split(separator: "/").map { String($0) }
//    }
//    
//    func appending(_ p: String) -> Path {
//        let list = p.split(separator: "/").map { String($0) }
//        var cp = subs
//        cp.append(contentsOf: list)
//        return Path(subs: list)
//    }
//
//    func appending(_ p: Path) -> Path {
//        var cp = Path()
//        cp.subs.append(contentsOf: p.subs)
//        return cp
//    }
//    public func mkdirs() -> Path? {
//        self
//    }
//}

//extension Path {
//    static var test: Path =
//    Path(subs: ["dir", "text", "joker"])
//}

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
