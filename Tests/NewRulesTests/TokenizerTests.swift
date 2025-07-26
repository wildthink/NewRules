//
//  Test.swift
//  NewRules
//
//  Created by Jason Jobe on 7/26/25.
//

import Testing
import Tokenizer

struct TokenizerTests {

    @Test func parse() async throws {
        let reader = Tokenizer(text: """
    key~= 0.894.
    ndx = 42
    fn = foo(a: 1) {
        print(x)
    }
    lines = #|
    line 1
    
    line 2
    |#
    list = [
        1 2 3
        alpha
        beta
    ]
    x <= 89
    """)
        
        while let tok = reader.read() {
            print(type(of: tok), tok)
        }
        print("done")
    }

}
