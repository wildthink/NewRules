//
//  LogModifier.swift
//  NewRules
//
//  Created by Jason Jobe on 8/25/24.
//
import Foundation

// MARK: Rule Modifiers
public struct ErrorRule: Builtin {
    public func run(environment: ScopeValues) throws {
        // throw error
    }
}

struct LogModifier: RuleModifier {
    @Scope(\.os_log) var os_log
    var msg: String
    
    func rules(_ content: Content) -> some Rule {
        os_log.debug("\(msg)")
        return content
    }
}

public extension Rule {
    func os_log(_ msg: String) -> some Rule {
        self.modifier(LogModifier(msg: msg))
    }
}
