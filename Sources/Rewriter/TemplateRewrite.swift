//
//  TemplateRewrite.swift
//  NewRules
//
//  Created by Jason Jobe on 8/27/24.
//
import Foundation
import NewRules

// TODO: Check for pre-existing file
// Write Modes
// - force_overwrite
// - keep_pre_existing
// - write only if different (avoid re-build)

public struct TemplateRewrite: Builtin {
    var pin: URL
    var pout: URL
    
    public init(in pin: URL, out: URL) {
        self.pin = pin
        self.pout = out
    }
    
    public func run(environment: ScopeValues) throws {
        let oldExists = FileManager.default.fileExists(atPath: pout.filePath)
        let mode = environment.template.mode
        if mode == .keep && oldExists {
            return
        }
        let txt = try String(contentsOf: pin)
        guard let data = environment.template.rewrite(txt).data(using: .utf8)
        else { throw NSError() }
        if oldExists,
           mode == .if_different,
           let old = try? String(contentsOf: pout),
           old == txt {
            return
        }
        try pout.deletingLastPathComponent().mkdirs()
        try data.write(to: pout)
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
    public enum WriteMode { case keep, overwrite, if_different }
    public static var defaultValue: Self = .init()
    
    public var values: [String: String] = [:]
    public var mode: WriteMode = .keep
    
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

public extension Rule {
    
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
    
    @warn_unqualified_access
    func template(mode: Template.WriteMode) -> some Rule {
        modifyEnvironment(keyPath: \.template) {
            $0.mode = mode
        }
    }
}

// MARK: - ScopeValues template
extension ScopeValues {
    public var template: Template {
        get { self[Template.self] }
        set { self[Template.self] = newValue }
    }
}
