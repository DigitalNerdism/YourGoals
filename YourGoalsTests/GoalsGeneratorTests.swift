//
//  YourGoalsTests.swift
//  YourGoalsTests
//
//  Created by André Claaßen on 22.10.17.
//  Copyright © 2017 André Claaßen. All rights reserved.
//

import XCTest
@testable import YourGoals

class GoalsGeneratorTests: StorageTestCase  {

    func testGeneratedGoals(testFunction: ([Goal]) -> Void ) {
        // setup
        let generator = TestDataGenerator(manager: self.manager)

        // act
        try! generator.generate()
        
        // test
        let retriever = StrategyManager(manager: self.manager)
        let strategy = try! retriever.retrieveActiveStrategy()!
        testFunction(strategy.allGoals())
    }
    
    func testGoals() {
        testGeneratedGoals {
            goals in

            XCTAssertEqual(2+1, goals.count, "2 generated goals and the virtually created today goal")
            
        }
    }
    
    func testTasks() {
        testGeneratedGoals { goals in
            for goal in goals {
                let tasks = goal.allTasks()
                XCTAssertEqual(3, tasks.count)
            }
        }
        
    }
    
}
