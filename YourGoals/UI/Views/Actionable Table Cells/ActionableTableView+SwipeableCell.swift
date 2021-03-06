//
//  ActionableTableView+SwipeableCell.swift
//  YourGoals
//
//  Created by André Claaßen on 01.11.17.
//  Copyright © 2017 André Claaßen. All rights reserved.
//

import Foundation
import MGSwipeTableCell

extension ActionableTableView: MGSwipeTableCellDelegate {
    
    // MARK: - configuration of the swipeable cell
    
    
    func configure(swipeableCell cell:MGSwipeTableCell) {
        cell.delegate = self
    }
    
    // MARK: - swipe button handling
    
    /// handle the swipe button with the needed swipe button behavior
    ///
    /// - Parameters:
    ///   - item: the actionable item
    ///   - date: the date
    ///   - behavior: the swipe button behavior
    /// - Throws: a core data expeciton
    func switchBehavior(item: ActionableItem, date: Date, behavior: ActionableBehavior) throws {
        guard let switchProtocol = self.dataSource?.switchProtocol(forBehavior: behavior) else {
            assertionFailure("no progress protocol for behavior \(behavior) available")
            return
        }
        
        // :hack:
        if behavior == .tomorrow {
            let tomorrow = date.addDaysToDate(1)
            try switchProtocol.switchBehavior(forItem: item, atDate: tomorrow)
        } else {
            try switchProtocol.switchBehavior(forItem: item, atDate: date)
        }
        
        self.tasksTableView.reloadData()
        guard let goal = item.actionable.goal else {
            NSLog("the actionable has no goal: \(item.actionable)")
            return
        }
        
        self.delegate.goalChanged(goal: goal)
    }
    
    
    // MARK: - MGSwipeTableCellDelegate
    
    func swipeTableCellWillBeginSwiping(_ cell: MGSwipeTableCell) {
        self.timerPaused = true
    }
    
    func swipeTableCellWillEndSwiping(_ cell: MGSwipeTableCell) {
        self.timerPaused = false
    }
    
    
    /// show the swipe buttons for the task
    ///
    /// - Parameters:
    ///   - cell: task
    ///   - direction: direction to swipe - from left to right or right to left
    ///   - swipeSettings: several settings
    ///   - expansionSettings: expansion settings
    /// - Returns: an array of MGSwipeButtons
    func swipeTableCell(_ cell: MGSwipeTableCell, swipeButtonsFor direction: MGSwipeDirection, swipeSettings: MGSwipeSettings, expansionSettings: MGSwipeExpansionSettings) -> [UIView]? {
        
        guard let taskCell = cell as? ActionableCell else {
            NSLog("illegal cell type: \(cell)")
            return nil
        }
        
        guard let item = taskCell.item else {
            NSLog("could not extract an item out of cell: \(taskCell)")
            return nil
        }
        
        swipeSettings.transition = MGSwipeTransition.border
        expansionSettings.buttonIndex = 0
        let swipeButtonCreator = ActionableSwipeButtonCreator()
        
        if direction == MGSwipeDirection.leftToRight {
            //            expansionSettings.fillOnTrigger = false
            //            expansionSettings.threshold = 2
            return  swipeButtonCreator.createSwipeButtons(forDate: Date(), item: item, forBehaviors: [.progress], dataSource: self.dataSource)
        }
        else {
            return swipeButtonCreator.createSwipeButtons(forDate: Date(), item: item, forBehaviors: [.commitment, .tomorrow], dataSource: self.dataSource)
        }
    }
    
    func swipeBehavior(index: Int, direction: MGSwipeDirection) -> ActionableBehavior {
        switch direction {
        case .leftToRight:
            switch index {
            case 0:
                return .progress
            case 1:
                return .state
            default:
                assertionFailure("not processable index for swipe cell: \(index)")
                return .state
            }
        case .rightToLeft:
            switch index {
            case 0:
                return .commitment
            case 1:
                return .tomorrow
            default:
                assertionFailure("not processable index for swipe cell: \(index)")
                return .state
            }
        @unknown default:
            fatalError("this is an unknown case")
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
            guard let taskCell = cell as? ActionableCell else {
                NSLog("illegal cell type: \(cell)")
                return true
            }
            
            guard let item = taskCell.item else {
                NSLog("the task cell has no actionable")
                return true
            }
            
            let behavior = swipeBehavior(index: index, direction: direction)
            try switchBehavior(item: item, date: Date(), behavior: behavior)
        }
        catch let error {
            self.delegate?.showNotification(forError: error)
        }
        
        return true
    }
}
