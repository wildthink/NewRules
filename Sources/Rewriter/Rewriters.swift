//
//  DirectoryRewrite.swift
//  NewRules
//
//  Created by Jason Jobe on 8/14/24.
//

import Foundation
import NewRules

public struct Rewrite: Rule {
    
    @Scope(\.template) var template
    var pin: URL
    var pout: URL
    
    public init(in fin: URL, out: URL) {
        self.pin = fin
        self.pout = out
    }
    
    func skip(_ url: URL) -> Bool {
        url.lastPathComponent == "Build"
    }
    
    public var body: some Rule {
        
        let pout = template.rewrite(pout)
        
        switch pin.uti {
            case _ where skip(pin):
                EmptyRule()
                
            case _ where pin.pathExtension == "xcassets":
                Copy(in: pin, out: pout)
                
            case .pbxproj:
                TemplateRewrite(in: pin, out: pout)

            case .text, .propertyList:
                TemplateRewrite(in: pin, out: pout)
                
            case .folder, .directory, .package:
                folder(in: pin, out: pout)

            default:
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
        if environment.template.mode != .keep {
            try? FileManager.default.removeItem(at: pout)
        }
        try FileManager.default.copyItem(at: pin, to: pout)
    }
}
