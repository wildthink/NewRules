//
//  Schedule.swift
//  NewRules
//
//  Created by Jason Jobe on 7/28/25.
//


import Foundation
import Testing
@_spi(InternalScope)
@testable import Tokenizer

struct ScheduleTests {
    
    @Test func testAll() async throws {
        /*
         Original DSL: 2025m1
         Human: in 2025, months 1
         Round-Trip DSL: 2025m1
         -----
         Original DSL: ym[Mon]
         Human: every Mon
         Round-Trip DSL: m* [Mon] (or similar if normalized)
         -----
         Original DSL: ym[Mon:1]
         Human: first Mon
         Round-Trip DSL: m* [Mon:1]
         ...
         */
        testSchedules()
    }
}

