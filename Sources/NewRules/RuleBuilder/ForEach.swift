//
//  ForEach.swift
//  
//
//  Created by Chris Eidhof on 01.06.21.
//

import Foundation

public struct ForEach<Element, Content: Rule>: Builtin {
    public init(_ data: [Element], @RuleBuilder content: @escaping (Element) -> Content) {
        self.data = data
        self.content = content
    }
    
    var data: [Element]
    var content: (Element) -> Content
    
    public func run(environment: ScopeValues) throws {
        for element in data {
            try content(element).builtin.run(environment: environment)
        }
    }
}
