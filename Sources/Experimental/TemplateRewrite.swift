//
//  TemplateRewrite.swift
//  NewRules
//
//  Created by Jason Jobe on 8/27/24.
//
import Foundation
import NewRules

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

// MARK: Template Enviroment Values
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
