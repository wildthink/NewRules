//
//  Tokenizer.swift
//  duckfs
//
//  Created by Jason Jobe on 7/25/25.
//
import Foundation

public class Tokenizer<Input: StringProtocol>  {
    var curs: StringScanner<Input>
    
    public init(text: Input) {
        self.curs = .init(text)
    }
    
    public func read() -> Any? {
        guard let pre = curs.currentChar
        else { return nil }
        
        switch pre {
            case CharacterSet.whitespaces:
                curs.skip(.whitespaces)
                return read()
                
            case "[":
                return loop(from: "[", to: "]")
                
            case "{":
                return loop(from: "{", to: "}")
                
            case "(":
                return loop(from: "(", to: ")")
                
            case "#" where curs.peek(by: 2) == "#|":
                return text(from: "#|", to: "|#")
                
            case CharacterSet.letters:
                let sym = curs.scan(.letters)
                if curs.currentChar == ":" {
                    curs.advance()
                    return KeyValue(key: sym, value: read())
                } else {
                    return sym
                }
                
            case CharacterSet.decimalDigits:
                return curs.scanNumber()
                
            case cmp_chars:
                return curs.scan(cmp_chars)
                
            case CharacterSet.punctuationCharacters:
                return curs.scan(.punctuationCharacters)
                
            case CharacterSet.newlines:
                curs.skip(.newlines)
                return read()
                
            default:
                return nil
        }
    }
    
    let cmp_chars = CharacterSet(charactersIn: "=~<>")
    
    func text(
        key: String = "text",
        from: any StringProtocol,
        to end: any StringProtocol
    ) -> TextBlock? {
        _ = curs.skip(from)
        curs.skip(.whitespacesAndNewlines)
        let lines = curs.lines(upto: end).map(\.description)
        return TextBlock(key: key, lines: lines)
    }
    
    func loop(from: any StringProtocol, to: any StringProtocol) -> [Any] {
        guard curs.skip(from) else { return [] }
        var arr: [Any] = []
        while let elem = read(), to.notEq(elem) {
            arr.append(elem)
        }
        return arr
    }
}

public struct KeyValue: CustomStringConvertible {
    public let key: any StringProtocol
    public let value: Any?
    public var description: String {
        if let value {
            "(\(key): \(String(describing: value)))"
        } else {
            "(\(key): nil)"
        }
    }
    public init(key: any StringProtocol, value: Any?) {
        self.key = key
        self.value = value
    }
}

public struct TextBlock: CustomStringConvertible {
    public let key: any StringProtocol
    public let lines: [String]
    public var description: String {
        "(\(key)): \(lines)"
    }
    public init(key: any StringProtocol, lines: [String]) {
        self.key = key
        self.lines = lines
    }
}

extension StringScanner {
    
    func hasPrefix(_ str: any StringProtocol) -> Bool {
        let ndx = index.utf16Offset(in: input)
        guard ndx + str.count <= input.count else { return false }
        let end = input.index(index, offsetBy: str.count)
        return input[index..<end] == str
    }
    
    mutating func lines(upto del: any StringProtocol
    ) -> [any StringProtocol] {
        var lines: [any StringProtocol] = []
        var start = index
        
        while hasInput {
            if isAt(.newlines) {
                // NOTE: We have check for newlines one at a time
                // and do this little dance to make sure catch
                // blank separator lines
                let line = input[start..<index]
                if line.hasPrefix(del) {
                    break
                }
                if line.hasPrefix("\n") {
                    lines.append("\n")
                    lines.append(line.dropFirst())
                } else {
                    lines.append(line)
                }
                _ = skip("\n")
                start = index
            } else if hasPrefix(del) {
                // End-of-Block
                let last_line = input[start..<index]
                    .description
                    .trimmingCharacters(in: .whitespaces)
                if !last_line.isEmpty {
                    lines.append(last_line)
                }
                _ = skip(del)
                break
            } else if !hasInput {
                // EOF reached, capture remaining text
                lines.append(input[start..<input.endIndex])
                break
            }
            advance()
        }
        return lines
    }
}

extension StringProtocol {
    
    func notEq(_ any: Any?) -> Bool {
        !self.eq(any)
    }
    
    func eq(_ any: Any?) -> Bool {
        guard let str = any as? any StringProtocol
        else { return false }
        return self == str
    }
}

func ~=(lhs: CharacterSet, rhs: UnicodeScalar) -> Bool {
    return lhs.contains(rhs)
}

func ~=(lhs: CharacterSet, rhs: Character) -> Bool {
    guard let ch = rhs.unicodeScalars.first
    else { return false }
    return lhs.contains(ch)
}

func ~=(lhs: CharacterSet, rhs: any StringProtocol) -> Bool {
    guard let ch = rhs.unicodeScalars.first
    else { return false }
    return lhs.contains(ch)
}
