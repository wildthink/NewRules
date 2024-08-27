//
//  DirectoryRewrite.swift
//  NewRules
//
//  Created by Jason Jobe on 8/14/24.
//

import Foundation
import NewRules

struct Rewrite: Rule {
    
    @Scope(\.template) var template
    var pin: URL
    var pout: URL
    
    init(in fin: URL, out: URL) {
        self.pin = fin
        self.pout = out
    }
    
    var body: some Rule {
        
        let pout = template.rewrite(pout)
        
        switch pin.uti {
            case .pbxproj:
                TemplateRewrite(in: pin, out: pout)

            case .folder:
                folder(in: pin, out: pout)

            case .text:
                TemplateRewrite(in: pin, out: pout)

            case .propertyList:
                TemplateRewrite(in: pin, out: pout)

            case _ where pin.pathExtension == "xcassets":
                Copy(in: pin, out: pout)

            case .directory, .package:
                folder(in: pin, out: pout)

            default:
                TraceRule(msg: "Copy \(pin.filePath) to \(pout.filePath)")
                Copy(in: pin, out: pout)
        }
    }
    
    func folder(in fin: URL, out fout: URL) -> some Rule {
        DirectoryRewrite(in: fin, out: fout) {
            Rewrite(in: $0, out: $1)
        }
    }
}

struct DirectoryRewrite<Content: Rule>: Rule {
    
    @Scope(\.template) var template
    var pin: URL
    var pout: URL
    @RuleBuilder var content: (URL, URL) -> Content
    
    init(in pin: URL, out pout: URL, content: @escaping (URL, URL) -> Content) {
        self.pin = pin
        self.pout = pout
        self.content = content
    }

    var body: some Rule {
        if let directoryFiles = try? pin.directoryContents() {
            ForEach(directoryFiles) { (fin: URL) in
                let fout = template.rewrite(pout.appending(path: fin.lastPathComponent))
                content(fin, fout)
            }
        }
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

// MARK: URL Extensions
import UniformTypeIdentifiers

public extension UTType {
    static var pbxproj: UTType =
    UTType(filenameExtension: "pbxproj", conformingTo: .text)!
}

func ~= (pattern: UTType?, value: UTType?) -> Bool {
    guard let pattern, let value else { return false }
    return value.conforms(to: pattern)
}

extension URL {

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
