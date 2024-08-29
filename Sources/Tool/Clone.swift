//
//  Clone.swift
//  NewRules
//
//  Created by Jason Jobe on 8/27/24.
//

import Foundation
import NewRules
import Rewriter


@main
struct Runner {
    static func main() async throws {
        // HACK:
        #if DEBUG
        let argv = CommandLine.arguments.first!.hasSuffix("Debug/clone")
        ? targs : CommandLine.arguments
        let args = CommandArguments(argv: argv)
        #else
        let args = CommandArguments()
        #endif
        
        guard !args.showHelp, !args.rest.isEmpty,
              let base:URL = args.base.first,
              let output:URL = args.output.first,
              let app = args.app.first
        else {
            help()
            return
        }
        
        let date = (args.test
                    ? Date(timeIntervalSince1970: 0)
                    : Date())
            .formatted(date: .abbreviated, time: .shortened)
        
        let copyright = args.copywrite.first ?? "See project License"
        
        let context: [String: CustomStringConvertible] = [
            "APP": app,
            "NOW": date,
            "COPYRIGHT": copyright,
        ]
        
        @RuleBuilder
        var script: some Rule {
            ForEach(args.rest) {
                TraceRule(msg: "Rewrite \($0)")
                Rewrite(in: base/$0, out: output)
            }
        }
        
        try script
            .template(mode: .overwrite)
            .template(merge: context)
            .run()
    }
    
    static func help() {
        print(
        """
        Useage: clone -base <base> -output <directory> -app <APP> template_names...
        """)
    }
}

#if DEBUG
// clone -base ~/dev/constellation/mac -output /tmp/b3 -app Pink MacApp
let targs = [
    "clone",
    "-base",
    "/Users/jason/dev/constellation/mac",
    "-output",
    "/tmp/c3",
    "-app",
    "Blue",
    "MacApp",
    "packs/DocAppPack",
]
#endif
