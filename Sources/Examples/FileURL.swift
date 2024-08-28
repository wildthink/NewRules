//
//  FileURL.swift
//  NewRules
//
//  Created by Jason Jobe on 8/27/24.
//
import Foundation
import UniformTypeIdentifiers

/// This overload of the matching operator for ``UTType`` enables a
/// a clean ergonmic and safer check using the UTType confomance
/// hierarchy.
func ~= (pattern: UTType?, value: UTType?) -> Bool {
    guard let pattern, let value else { return false }
    return value.conforms(to: pattern)
}

// MARK: URL Extensions
prefix operator ~/

/// This prefix operator provides a natural ergomic reference
/// to the user's home directory
public prefix func ~/ (lhs: any StringProtocol) -> URL {
    FileManager.default
        .homeDirectoryForCurrentUser
        .appending(path: lhs)
}

/// This prefix operator provides a natural ergomic reference
/// to the user's home directory
public prefix func ~/ (lhs: URL) -> URL {
    FileManager.default
        .homeDirectoryForCurrentUser
        .appending(path: lhs.filePath)
}

public extension URL {
    
    /// This infix operator provides a natural ergomic for
    /// composing URL path components.
    static func / (lhs: URL, rhs: any StringProtocol) -> URL {
        if lhs.path().hasPrefix("~/") {
            (~/lhs.path().dropFirst(2))
                .appending(path: rhs)
                .standardizedFileURL
        } else {
            lhs.appending(path: rhs)
                .appending(path: rhs)
                .standardizedFileURL
        }
    }
    
    /// The mkdirs() function provides a convience call to the FileManager
    /// to create a fully reified path in the file system.
    func mkdirs(_fm: FileManager = .default) throws {
        try _fm.createDirectory(at: self, withIntermediateDirectories: true)
    }
    
    /// The directoryContents() function provides a convience call the the
    /// FileManager to provide an array of a directory's children.
    func directoryContents(_fm: FileManager = .default) throws -> [URL] {
        try _fm
            .contentsOfDirectory(at: self,
                includingPropertiesForKeys:[
                    .isDirectoryKey, .isPackageKey,
                    .isRegularFileKey, .contentTypeKey],
                options: .skipsHiddenFiles)
    }
    
    /// The computed property `uti` is a convience call the retrieve the
    /// appropriate resourceValue for the contentType for the URL.
    var uti: UTType? {
        let rvs = try? self.resourceValues(forKeys: [.contentTypeKey])
        return rvs?.contentType
    }
    
    /// The computed property `filePath` is a convience call to return
    /// a proper file system path, expanding "~/" and standardizing the path.
    var filePath: String {
        if path().hasPrefix("~/") {
            (~/path().dropFirst(2)).standardizedFileURL.path
        } else {
            standardizedFileURL.path
        }
    }
}

extension URL: @retroactive ExpressibleByStringLiteral {
    /// The convience URL init expands the "~/" prefix if found
    public init(stringLiteral value: String) {
        if value.hasPrefix("~/") {
            self = ~/value.dropFirst(2)
        } else {
            self = URL(fileURLWithPath: value)
        }
    }
}

// MARK: UTType Extensions
public extension UTType {
    /// The UTType for Xcode project.pbxproj files
    static var pbxproj: UTType =
    UTType(filenameExtension: "pbxproj", conformingTo: .text)!
}
