//
//  PlistRewrite.swift
//  NewRules
//
//  Created by Jason Jobe on 8/29/24.
//

import Foundation
import NewRules


public struct PlistRewrite: Builtin {
    var pin: URL
    var pout: URL
    
    public init(in pin: URL, out: URL) {
        self.pin = pin
        self.pout = out
    }
    
    public func run(environment: ScopeValues) throws {

        // The input is a template
        var txt = try String(contentsOf: pin)
        txt = environment.template.rewrite(txt)
        let data = txt.data(using: .utf8)
        guard let plist = try data?.deserializePlist()
        else {
            throw PlistError
                .expectingFormat(fmt: "Dictionary", path: pin.filePath)
        }
        
        // All __VAR__ were previously converted
        if let cur_plist: NSMutableDictionary = try? .new(withContentsOf: pout) {
            try plist.overwrite(with: cur_plist)
        }
        try pout.deletingLastPathComponent().mkdirs()
        try plist.write(to: pout)
    }
}

extension Data {
    
    func deserializePlist() throws -> NSMutableDictionary {
        // Deserialize the plist data into a dictionary
        var format = PropertyListSerialization.PropertyListFormat.xml
        let plist = try PropertyListSerialization
            .propertyList(from: self,
                          options: .mutableContainersAndLeaves,
                          format: &format)
        
        // Check if the plist is a dictionary
        guard let dictionary = plist as? NSMutableDictionary else {
            throw PlistError.expectingFormat(fmt: "Dictionary", path: "")
        }
        return dictionary
    }
}

extension Template {
    func rewrite(any: Any) -> Any {
        switch any {
            case let it as String:
                rewrite(it)
            case let it as URL:
                rewrite(it)
            case let it as NSMutableArray:
                rewrite(plist: it)
            case let it as NSMutableDictionary:
                rewrite(plist: it)
            default:
                any
        }
     }
    
    func rewrite(plist: NSArray) -> [Any] {
        plist.map { rewrite(any: $0) }
    }
    
    func rewrite(plist: NSMutableDictionary) {
        for (k, v) in plist {
            guard let k = rewrite(any: k) as? NSCopying
            else { continue }
            plist.setObject(rewrite(any: v), forKey: k)
        }
    }
}

enum PlistError: Error {
    case missingFile(String)
    case corruptedFile(String)
    case expectingFormat(fmt: String, path: String)
    case notimplemented(String)
}

extension NSMutableDictionary {
    
    func overwrite(with other: NSDictionary) throws {
        guard let other = other as? [String:Any]
        else { throw PlistError.expectingFormat(fmt: "Dictionary", path: "") }

        for (k, v) in other {
            self.setValue(v, forKey: k)
            // TBD: Can we do this nested?
//            switch (dv, v) {
//                case (nil, _):
//                    self.setValue(v, forKey: k)
//                case let (d as NSMutableDictionary, it as NSDictionary):
//                    try d.overwrite(with: it)
//                case let (_ as NSArray, it as NSArray):
//                    self.setValue(it, forKey: k)
//                default:
//                    self.setValue(v, forKey: k)
//            }
        }
    }
    
    func writeAsPlist(to url: URL) throws {
        let data = try PropertyListSerialization
            .data(fromPropertyList: self, format: .xml, options: 0)
        try data.write(to: url)
    }
    
    static func new(withContentsOf url: URL) throws -> NSMutableDictionary {
        try new(withContentsOf: url.filePath)
    }
    
    static func new(withContentsOf path: String) throws -> NSMutableDictionary {
        guard FileManager.default.fileExists(atPath: path)
        else { throw PlistError.missingFile(path) }
        
        guard let data = NSData(contentsOfFile: path)
        else { throw PlistError.corruptedFile(path) }
        
        // Deserialize the plist data into a dictionary
        var format = PropertyListSerialization.PropertyListFormat.xml
        let plist = try PropertyListSerialization.propertyList(from: data as Data, options: .mutableContainersAndLeaves, format: &format)
        
        // Check if the plist is a dictionary
        if let dictionary = plist as? NSMutableDictionary {
            return dictionary
        } else { throw PlistError.expectingFormat(fmt: "Dictionary", path: path) }
    }
}

