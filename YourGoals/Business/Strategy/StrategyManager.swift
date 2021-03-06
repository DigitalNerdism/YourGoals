//
//  Strategy.swift
//  YourGoals
//
//  Created by André Claaßen on 24.10.17.
//  Copyright © 2017 André Claaßen. All rights reserved.
//

import Foundation
import UIKit

enum StrategyManagerError : Error{
    case activeStrategyMissingError
}

extension StrategyManagerError:LocalizedError {
    var errorDescription: String? {
        switch self {
        case .activeStrategyMissingError:
            return "There is no active strategy available. operation aborted"
        }
    }
}

class StrategyManager:StorageManagerWorker {
    
    /// assert, that a strategy exists
    ///
    /// - Returns: the strategy
    /// - Throws: an excepiton
    private func assertActiveStrategy() throws -> Goal {
        let strategy = try retrieveActiveStrategy()
        if strategy == nil {
            let newStrategy = try GoalFactory(manager: self.manager).create(name: "Strategy", prio: 0, reason: "Master Plan", startDate: Date.minimalDate, targetDate: Date.maximalDate, image: nil, type: .strategyGoal, backburnedGoals: false)
            try self.manager.saveContext()
            return newStrategy
        }
        
        return strategy!
    }
    
    @discardableResult
    
    /// assert a today goal for the strategy and returns it.
    ///
    /// - Parameter strategy: the strategy
    /// - Returns: a valid today goal
    /// - Throws: core data exception
    func assertTodayGoal(strategy:Goal) throws -> Goal  {
        if let todayGoal = strategy.allGoals().first(where: { $0.type == GoalType.todayGoal.rawValue })   {
            return todayGoal
        }
        
        let todayGoal = try GoalFactory(manager: self.manager).create(name: "Today", prio: 0, reason: "Your tasks for today. You have committed them all", startDate: Date.minimalDate, targetDate: Date.maximalDate, image: Asset.yourToday.image, type: .todayGoal, backburnedGoals: false)
        
        strategy.addToSubGoals(todayGoal)
        try manager.saveContext()
        return todayGoal
    }

    func assertValidActiveStrategy() throws -> Goal {
        let strategy = try assertActiveStrategy()
        try assertTodayGoal(strategy: strategy)
        return strategy
    }
    
    /// retrieve the active strategy from core data
    ///
    /// - Returns: the active strategy or nil
    /// - Throws: core data excepption
    func retrieveActiveStrategy() throws -> Goal? {
        
        let strategy =  try self.manager.goalsStore.fetchFirstEntry {
            $0.predicate = NSPredicate(format: "(parentGoal = nil)")
        }
        
        return strategy
    }
    
    /// add a goal to the strategy
    ///
    /// - Parameter goal: the newly created goal
    /// - Throws: core data exception
    private func add(goal: Goal, toStrategy strategy: Goal) throws {
        assert(goal.parentGoal == nil, "this goal shouldn't be part of a strategy")
        
        strategy.addToSubGoals(goal)
        try manager.saveContext()
    }
    
    
    /// add the goal to the current strategy and save it back to the data base
    ///
    /// - Parameter goal: the goal
    /// - Returns: a newly created goal
    /// - Throws: core data exception
    func createNewGoalForStrategy(goalInfo: GoalInfo) throws -> Goal  {
        guard let strategy = try self.retrieveActiveStrategy() else {
            throw StrategyManagerError.activeStrategyMissingError
        }
        
        let goal = try GoalFactory(manager: self.manager).create(fromGoalInfo: goalInfo)
        try self.add(goal: goal, toStrategy: strategy)
        return goal
    }
}
