//
//  GoalComposer.swift
//  YourGoals
//
//  Created by André Claaßen on 27.10.17.
//  Copyright © 2017 André Claaßen. All rights reserved.
//

import Foundation
import CoreData

enum GoalComposerError:Error {
    case noTaskForIdFound
}

/// modify and compose goals in core data and save the result in the database
class GoalComposer:StorageManagerWorker {
    /// add a new task with the information from the task info to the goal and save
    /// it back to the core data store
    ///
    /// - Parameters:
    ///   - actionableInfo: task info
    ///   - goal: the goal
    /// - Returns: the modified goal with the new task
    /// - Throws: core data exception
    func create(actionableInfo: ActionableInfo, toGoal goal: Goal) throws -> Goal {
        let factory = factoryForType(actionableInfo.type)
        var actionable = factory.create(actionableInfo: actionableInfo)
        actionable.prio = -1
        goal.add(actionable: actionable)
        let taskOrderManager = TaskOrderManager(manager: self.manager)
        taskOrderManager.updateOrderByPrio(forGoal: goal, andType: actionableInfo.type)
        try self.manager.dataManager.saveContext()
        return goal
    }

    /// update a task for a goal withnew valuees
    ///
    /// - Parameters:
    ///   - actionableInfo: task info
    ///   - id: object id of the task
    ///   - goal: the goal
    /// - Returns: the modified goal with the updated task
    /// - Throws: core data exception
    
    func update(actionableInfo: ActionableInfo, withId id: NSManagedObjectID, toGoal goal: Goal) throws -> Goal {
        guard let task = goal.taskForId(id) else {
            throw GoalComposerError.noTaskForIdFound
        }
        
        task.name = actionableInfo.name
        try self.manager.dataManager.saveContext()
        return goal
    }
    
    /// delete a task with id from the given goal
    ///
    /// - Parameters:
    ///   - id: object id from the task
    ///   - goal: the parent goal for the task
    /// - Returns: the goal without the task
    /// - Throws: core data exception
    func delete(taskWithId id:NSManagedObjectID, fromGoal goal: Goal) throws -> Goal {
        guard let task = goal.taskForId(id) else {
            throw GoalComposerError.noTaskForIdFound
        }

        goal.removeFromTasks(task)
        self.manager.tasksStore.managedObjectContext.delete(task)
        try self.manager.dataManager.saveContext()
        return goal
    }
    
    func factoryForType(_ type:ActionableType) -> ActionableFactory {
        switch type {
        case .task:
            return TaskFactory(manager: self.manager)
            
        case .habit:
            return HabitFactory(manager: self.manager)
        }
    }
    
    
    

}
