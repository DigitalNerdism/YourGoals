//
//  GoalDetailViewController+SwipeableCell.swift
//  YourGoals
//
//  Created by André Claaßen on 27.10.17.
//  Copyright © 2017 André Claaßen. All rights reserved.
//

import Foundation
import UIKit
import MGSwipeTableCell

// MARK: - handle a goal in detail.
extension GoalDetailViewController : MGSwipeTableCellDelegate {
    
    // MARK: - configuration of the swipeable cell
    
    func configure(swipeableCell cell:MGSwipeTableCell) {
        cell.delegate = self
    }
    
    // MARK: - progress handling
    
    func switchProgress(forTask task: Task) throws {
        let date = Date()
        let progressManager = TaskProgressManager(manager: self.manager)
        if task.isProgressing(atDate: date) {
            try progressManager.stopProgress(forTask: task, atDate: date)
        } else {
            try progressManager.startProgress(forTask: task, atDate: date)
        }
    }
    
    func switchState(forTask task: Task) throws {
        let date = Date()
        let stateManager = TaskStateManager(manager: self.manager)
        if task.taskIsActive() {
            try stateManager.setTaskState(task: task, state: .done, atDate: date)
        } else {
            try stateManager.setTaskState(task: task, state: .active, atDate: date)
        }
    }
    
    
    // MARK: - Swipe Cell creator funciton
    
    /// create a swipe button for starting/stoping making progress
    ///
    /// - Parameter task: a task
    /// - Returns: a configured MGSwipeButton
    func createSwipeButtonForProgress(task: Task) -> MGSwipeButton {
        let isProgressing = task.isProgressing(atDate: Date())
        let title = isProgressing ? "Stop task" : "Start task"
        let backgroundColor = isProgressing ? UIColor.red : UIColor.green
        return MGSwipeButton(title: title, backgroundColor: backgroundColor)
    }
    
    func createSwipeButtonForState(task: Task) -> MGSwipeButton {
        let title = task.taskIsActive() ? "Task Done" : "Task Open"
        return MGSwipeButton(title: title, backgroundColor: UIColor.blue)
    }
    
    // MARK: - MGSwipeTableCellDelegate
    
    /// show the swipe buttons for the task
    ///
    /// - Parameters:
    ///   - cell: task
    ///   - direction: direction to swipe - from left to right or right to left
    ///   - swipeSettings: several settings
    ///   - expansionSettings: expansion settings
    /// - Returns: an array of MGSwipeButtons
    func swipeTableCell(_ cell: MGSwipeTableCell, swipeButtonsFor direction: MGSwipeDirection, swipeSettings: MGSwipeSettings, expansionSettings: MGSwipeExpansionSettings) -> [UIView]? {
        
        guard let taskCell = cell as? TaskTableViewCell else {
            NSLog("illegal cell type: \(cell)")
            return nil
        }
        
        guard let task = taskCell.task else {
            NSLog("could not extract task out of cell: \(taskCell)")
            return nil
        }
        
        
        swipeSettings.transition = MGSwipeTransition.border
        expansionSettings.buttonIndex = 0
        
        if direction == MGSwipeDirection.leftToRight {
            expansionSettings.fillOnTrigger = false
            expansionSettings.threshold = 2
            return [createSwipeButtonForProgress(task: task)]
        }
        else {
            return [createSwipeButtonForState(task: task)]
        }
    }
    
    /// handle a tapped swipe button
    ///
    /// - Parameters:
    ///   - cell: for task cell
    ///   - index: index of the button, if there are several butotns
    ///   - direction: left to right or right ot left
    ///   - fromExpansion:
    /// - Returns: true for old good handlign
    func swipeTableCell(_ cell: MGSwipeTableCell, tappedButtonAt index: Int, direction: MGSwipeDirection, fromExpansion: Bool) -> Bool {
        do {
            guard let taskCell = cell as? TaskTableViewCell else {
                NSLog("illegal cell type: \(cell)")
                return true
            }
            
            guard let task = taskCell.task else {
                NSLog("could not extract task out of cell: \(taskCell)")
                return true
            }
            
            switch direction {
            case .leftToRight:
                try switchProgress(forTask: task)
                break
                
            case .rightToLeft:
                try switchState(forTask: task)
                break
            }
        }
        catch let error {
            self.showNotification(forError: error)
        }
        
        return true
    }
}
