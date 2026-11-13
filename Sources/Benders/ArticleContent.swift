//
//  ArticleContent.swift
//  Simone
//
//  Created by Jason Jobe on 8/13/26.
//

import NewRules

protocol ArticleContent: Rule {
    func render() -> [String]
}

extension ArticleContent {
    public var body: some ArticleContent {
        Heading(text: "")
    }
}

//@frozen
public struct TupleContent<each Content> {
    public var content: (repeat each Content)
}

//extension TupleContent: ArticleContent {}

//#if TUPLE_

struct Heading: ArticleContent {

    let text: String

    func render() -> [String] {
        ["# \(text)"]
    }
}

struct Paragraph: ArticleContent {
    let text: String

    func render() -> [String] {
        [text]
    }
}

extension TupleContent: Rule
where repeat each Content: Rule {
    public var body: some Rule {
        for element in repeat each content {
//            output += element.render()
        }
        return EmptyRule()
    }
//    func render() -> [String] {
//        var output: [String] = []
//        
//        for element in repeat each content {
//            output += element.render()
//        }
//        
//        return output
//    }
}

extension Optional: ArticleContent
where Wrapped: ArticleContent {
    func render() -> [String] {
        self?.render() ?? []
    }
}

//extension _ConditionalContent: ArticleContent
//where TrueContent: ArticleContent,
//      FalseContent: ArticleContent {
//    func render() -> [String] {
//        switch storage {
//            case let .trueContent(content):
//                content.render()
//            case let .falseContent(content):
//                content.render()
//        }
//    }
//}

//extension ForEach: ArticleContent
//where Content: ArticleContent {
//    func render() -> [String] {
//        data.flatMap { content($0).render() }
//    }
//}

@RuleBuilder
func article(showNote: Bool) -> some ArticleContent {
    Heading(text: "ContentBuilder")
    Paragraph(text: "Assemble the structure first, verify the capability after.")
    
    if showNote {
        Paragraph(text: "This is an optional passage.")
    }
    
    ForEach(
        ["Remove the overloads", "Conditional conformance"],
        id: \.self
    ) {
        Paragraph(text: $0)
    }
}

import Playgrounds

#Playground {
    
}
//#endif
