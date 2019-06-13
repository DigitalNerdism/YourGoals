//
//  TaskWorkingTimeTextCreator.swift
//  YourGoals
//
//  Created by André Claaßen on 13.06.19.
//  Copyright © 2019 André Claaßen. All rights reserved.
//

import Foundation

/// helper for formatting the text of an task actionable table cell
struct TaskWorkingTimeTextCreator {
    
    /// calculate several textes for the working time and progress
    /// of the actionables
    ///
    /// - Parameters:
    ///   - actionable: the task or habit
    ///   - date: calculate values for this date
    ///   - estimatedStartingTime: estimated starting time of the task
    /// - Returns: a tuple consisting of formatted strings of
    ///            workingTimeRange, remaining time and the total working time
    func getTimeLabelTexts(actionable: Actionable, forDate date: Date, estimatedStartingTime: Date?) -> (workingTime:String?, remainingTime: String?, totalWorkingTime: String?) {
        guard actionable.type == .task else {
            return (nil, nil, nil)
        }
        
        let totalWorkingTime = actionable.calcProgressDuration(atDate: date)?.formattedAsString()
        
        guard actionable.checkedState(forDate: date) == .active else {
            return (nil, nil, totalWorkingTime)
        }
        
        let remainingTime = actionable.calcRemainingTimeInterval(atDate: date)
        let remainingTimeText = remainingTime.formattedAsString()
        
        if let startingTime = estimatedStartingTime {
            
            let endingTime = date.compare(startingTime) == .orderedDescending ?  date.addingTimeInterval(remainingTime) : startingTime.addingTimeInterval(remainingTime)
            
            let workingTimeText = "\(startingTime.formattedTime()) - \(endingTime.formattedTime()) (\(remainingTime.formattedInMinutesAsString()))"
            return (workingTimeText, remainingTimeText, totalWorkingTime)
        } else {
            return (nil, remainingTimeText, totalWorkingTime)
        }
    }
}
