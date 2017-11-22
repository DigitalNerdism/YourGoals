//
//  GoalProgressCalculator.swift
//  YourGoals
//
//  Created by André Claaßen on 27.10.17.
//  Copyright © 2017 André Claaßen. All rights reserved.
//

import Foundation

/// progress indicator
///
/// - met: 95% - 100%
/// - ahead: 20% more ahead
/// - onTrack: + / - 20%
/// - lagging: 20% behind
/// - behind: >50% behind
/// - notStarted: no progress at allo
enum ProgressIndicator {
    case met
    case ahead
    case onTrack
    case lagging
    case behind
    case notStarted
}

/// this class calculates the progress on this goal in percent
class GoalProgressCalculator:StorageManagerWorker {
    
    /// calculate the progress made on this goal. compare progress of tasks done versus progress of time elapsed
    ///
    /// - Parameters:
    ///   - goal: the goal
    ///   - date: the date for comparision
    /// - Returns: progress of tasks in percent and a progress indicator
    func calculateProgress(forGoal goal: Goal, forDate date: Date) throws -> (progress:Double, indicator:ProgressIndicator) {
        let progressTasks = try calculateProgressOfActionables(forGoal: goal, andDate: date)
        let progressDate = calculateProgressOfTime(forGoal: goal, forDate: date)
        let progressIndicator = calculateIndicator(progressTasks: progressTasks, progressDate: progressDate)
        return (progressTasks, progressIndicator)
    }
    
    /// calculate the progress of tasks done in per
    ///
    /// - Parameters
    ///     - goal: the goal
    ///     - date: the date for the actionables
    /// - Returns: ratio of done tasks and all tasks (between 0.0 and 1.0)
    func calculateProgressOfActionables(forGoal goal: Goal, andDate date: Date) throws -> Double {
        let dataSource = ActionableDataSourceProvider(manager: self.manager).dataSource(forGoal: goal, andType: goal.goalType() == .todayGoal ? nil : .task)
        
        let actionables = try dataSource.fetchActionables(forDate: date)
        if actionables .count == 0 {
            return 0.0
        }
        
        let numberOfDone = actionables.filter{ $0.checkedState(forDate: date) == .done}.count
        let progress = Double(numberOfDone) / Double(actionables.count)
        return progress
    }
    
    /// calculate the progress of time in relation to the given date
    ///
    /// - Parameters:
    ///   - goal: the goal
    ///   - date: the date for calculate the progress of time since start of the goal
    /// - Returns: progress of time elapsed from the goal (between 0.0 and 1.0)
    func calculateProgressOfTime(forGoal goal: Goal, forDate date:Date) -> Double {
        let range = goal.logicalDateRange(forDate: date)
        let startDate = range.start
        let endDate = range.end
        
        let timeSpanGoal = endDate.timeIntervalSince(startDate)
        let timeSpanForDate = date.timeIntervalSince(startDate)
        
        let percent = timeSpanForDate / timeSpanGoal
        if percent < 0.0 {
            return 0.0
        }
        
        if percent > 1.0 {
            return 1.0
        }
        
        return percent
    }
    
    /// calculate an indicator of progress relative to the time of the goal
    ///
    /// - Parameters:
    ///   - progressTasks: progress of the tasks in percent
    ///   - progressDate: progress of the date in percent
    /// - Returns: an indicator
    func calculateIndicator(progressTasks:Double, progressDate: Double) -> ProgressIndicator {
        if progressTasks == 0.0 {
            return .notStarted
        }
        
        if progressTasks >= 0.95 {
            return .met
        }
        
        if progressTasks - progressDate >= 0.20 {
            return .ahead
        }
        
        if progressTasks - progressDate >= -0.20 {
            return .onTrack
        }
        
        if progressTasks - progressDate  >= -0.50 {
            return .lagging
        }
        
        return .behind
    }
}
