//
//  XMLBuilder.swift
//  NewRules
//
//  Created by Jason Jobe on 8/9/26.
//

import Foundation
import NewRules
import Builders

public struct XMLBuilder: Sendable, Builtin {
    public func run(environment: ScopeValues) throws {
    }
}

struct XMLNode: Sendable, Rule {
    
    init() {}
    
    var body: some Rule {
        EmptyRule()
    }
    
    func cp(@RuleBuilder _ content: () -> some Rule) -> some Rule {
        content()
    }
    
    func xcp(@RuleBuilder _ content: () -> XMLNode) -> XMLNode {
        content()
    }
}

#if DEBUG
import Playgrounds

#Playground {

}

func foo() throws {
    let plist: [String:String] = .build {
        
    }
    let bob = XMLNode()
    
    let it = bob.cp {
        EmptyRule()
    }
    try it.run()
    print(it)
}

#endif
