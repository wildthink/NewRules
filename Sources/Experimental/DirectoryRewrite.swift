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
    var pin: URL
    var pout: URL

    init(in fin: URL, out: URL) {
        self.pin = fin
        self.pout = out
    }
    
    func directoryContents() -> [URL] {
        (try? pin.directoryContents()) ?? []
    }
    
    var body: some Rule {
        
        ForEach(directoryContents()) { (fin: URL) in
            
            let fout = template.rewrite(pout.appending(path: fin.lastPathComponent))

            switch fin.uti {
                case .pbxproj:
                    TemplateRewrite(in: fin, out: fout)
                case .folder:
                    DirectoryRewrite(in: fin, out: fout)
                case .text:
                    TemplateRewrite(in: fin, out: fout)
                case .propertyList:
                    TemplateRewrite(in: fin, out: fout)
                case _ where fin.pathExtension == "xcassets":
                    Copy(in: fin, out: fout)
                case .directory, .package:
                    DirectoryRewrite(in: fin, out: fout)
                default:
                    TraceRule(msg: "Copy \(fin.filePath) to \(fout.filePath)")
                    Copy(in: fin, out: fout)
            }
        }
    }
}

func ~= (pattern: UTType?, value: UTType?) -> Bool {
    guard let pattern, let value else { return false }
    return value.conforms(to: pattern)
}

struct TemplateRewrite: Builtin {
    var pin: URL
    var pout: URL
    
    init(in pin: URL, out: URL) {
        self.pin = pin
        self.pout = out
    }
    
    func run(environment: ScopeValues) throws {
        let txt = try String(contentsOf: pin)
        let data = environment.template.rewrite(txt).data(using: .utf8)
        try pout.deletingLastPathComponent().mkdirs()
        try data?.write(to: pout)
    }
}

struct Copy: Builtin {
    var pin: URL
    var pout: URL
    
    init(in pin: URL, out: URL) {
        self.pin = pin
        self.pout = out
    }
    
    func run(environment: ScopeValues) throws {
        try pout.deletingLastPathComponent().mkdirs()
        try FileManager.default.copyItem(at: pin, to: pout)
    }
}

// MARK: Enviroment Values
// Template
public struct Template: ScopeKey {
    public static var defaultValue: Self = .init()

    public var values: [String: String] = [:]
    
    public func rewrite(_ str: String) -> String {
        str
            .substituteKeys(del: "__", using: values)
            .substituteKeys(del: "--", using: values)
    }
    
    public func rewrite(_ p: URL) -> URL {
        let new = p.filePath
            .substituteKeys(del: "__", using: values)
            .substituteKeys(del: "--", using: values)
        return URL(fileURLWithPath: new)
    }
}

extension ScopeValues {
    public var template: Template {
        get { self[Template.self] }
        set { self[Template.self] = newValue }
    }
}

// MARK: URL Extensions
import UniformTypeIdentifiers

extension URL {
    
    var isDotFile: Bool {
        filePath.contains("/.")
    }
    
    func mkdirs() throws {
        try FileManager.default.createDirectory(at: self, withIntermediateDirectories: true)
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

// MARK: String Templating Extensions
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
