//
//  CommandArguments.swift
//  NewRules
//
//  Created by Jason Jobe on 8/28/24.
//
import Foundation

@dynamicMemberLookup
public class CommandArguments {
    public var exec: String = ""
    public var cmd: String?
    public var argm: [String: [String]] = [:]
    public var rest: [String] = []
    
    public var flags: Set<String> = .init()
    public var showHelp: Bool { self.h || self.help }
    
    func value<Value>(for key: String) -> [Value] {
        guard let sv = argm[key] ?? argm[key.uppercased()]
        else { return [] }

        return switch Value.self {
            case is String.Type:
                sv.map { $0 } as! [Value]
            case is Bool.Type:
                sv.map { $0.lowercased() == "true" } as! [Value]
            case is Int.Type:
                sv.map { Int($0) ?? 0 } as! [Value]
            case is Double.Type:
                sv.map { Double($0) ?? 0 } as! [Value]
            case is URL.Type:
                sv.map { URL(fileURLWithPath: $0) } as! [Value]
            default:
                []
        }
    }
    
    public subscript(dynamicMember key: String) -> Bool {
        let flags: [Bool] = value(for: key)
        return flags.last ?? false
    }

    public subscript(dynamicMember key: String) -> [String] {
        value(for: key)
    }

    public subscript<V>(dynamicMember key: String) -> [V] {
        value(for: key)
    }
}

public extension CommandArguments {
    /// The expected format of the command line arguments:
    ///  <exec> cmd? (-key=value | -key value)... rest...
    func parse(argv: [String] = CommandLine.arguments
    ) -> Self {
        var seq = argv.makeIterator()
        exec = seq.next() ?? ""
        if argv.count > 1, !argv[1].hasPrefix("-") {
            cmd = seq.next()
        }
        while let arg = seq.next() {
            if arg.hasPrefix("-") {
                let (k, v) = keyValue(arg.dropFirst())
                if flags.contains(k) {
                    // No value expected
                    append(k, value: "true")
                } else {
                    let v2 = v ?? seq.next()
                    append(k, value: v2)
                }
            } else {
                rest.append(arg)
            }
        }
        return self
    }
    
    func append(_ key: String, value: (any StringProtocol)?) {
        var cur = argm[key] ?? []
        cur.append(String(describing: value ?? ""))
        argm[key] = cur
    }
    
    func keyValue(_ str: String.SubSequence) -> (String, (any StringProtocol)?) {
        let pair = str.split(separator: "=", maxSplits: 1)
        if pair.count == 2 {
            return (String(pair[0]), pair[1])
        } else {
            return (String(pair[0]), nil)
        }
    }
}
