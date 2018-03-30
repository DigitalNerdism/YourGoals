//
//  TaskNotificationManager.swift
//  YourGoals
//
//  Created by André Claaßen on 26.03.18.
//  Copyright © 2018 André Claaßen. All rights reserved.
//

import Foundation
import UserNotifications

struct TaskNotificationIdentifier {
    static let timeIsRunningOut = "timeIsRunningOUt"
}

struct TaskNotificationCategory {
    static let taskNotificationCategory = "taskNotificationCategory"
}

/// a protocol for triggering the create of local user notifications
protocol TaskNotificationProviderProtocol {
    func startProgress(forTask task:Task, referenceDate:Date, remainingTime:TimeInterval)
    func stopProgress()
}

/// this class creates notification on started or stopped tasks
class TaskNotificationManager:TaskNotificationProviderProtocol {
     static let defaultManager = TaskNotificationManager()
    
    /// the user notification center
    let center:UNNotificationCenterProtocol

    
    /// initialize the task notification maanger with the user notification cente
    ///
    /// - Parameter notificationCenter: default is UNUserNotificationCenter.current() or a UnitTest Mockup
    init(notificationCenter:UNNotificationCenterProtocol = UNUserNotificationCenter.current()) {
        self.center = notificationCenter
        setupNotificationActions()
    }
    
    
    /// schedule a local notification for the task to informa about remaining time
    ///
    /// - Parameters:
    ///   - task: the task
    ///   - text: a notification text
    ///   - referenceDate: the reference date to calculate the notification time
    ///   - remainingTime: the remaining time for the task
    func scheduleLocalNotification(forTask task:Task, withText text:String, referenceDate: Date, remainingTime: TimeInterval) {
        guard let taskName = task.name else {
            NSLog("Task with no name")
            return
        }
        
        guard remainingTime > 0.0 else {
            NSLog("there is no time left for task \(taskName) to schedule a notification!")
            return
        }

        let content = UNMutableNotificationContent()
        content.categoryIdentifier = TaskNotificationCategory.taskNotificationCategory
        content.body = taskName
        content.title = text
        content.userInfo = [
            "task": task
        ]
        
        let scheduleTime = referenceDate.addingTimeInterval(remainingTime);
        let trigger = UNCalendarNotificationTrigger(fireDate: scheduleTime)
        let request = UNNotificationRequest(identifier: taskName , content: content, trigger: trigger)
        
        self.center.add(request, withCompletionHandler: nil)
    }
    

    
    func resetNotifications() {
        self.center.removeAllPendingNotificationRequests()
        self.center.removeAllDeliveredNotifications()
    }
    
    /// setup the custom actions for all motivation card notifications
    /// edit action for taking immediate input
    /// delay action for delaying a motivation card
    func setupNotificationActions() {
        
        let timeIsRunningOutAction = UNNotificationAction(
            identifier: TaskNotificationIdentifier.timeIsRunningOut ,
            title:  "Your time is over",
            options: [])

    
        let category = UNNotificationCategory(identifier: TaskNotificationCategory.taskNotificationCategory, actions: [timeIsRunningOutAction], intentIdentifiers: [], options: [])

        center.setNotificationCategories([category])
    }
    
    // mark: - TaskNotificationProviderProtocol
    
    /// inform the task notification manager about a start of a task
    ///
    /// - Parameters:
    ///   - task: the task
    ///   - referenceDate: the reference date for calculation
    ///   - remainingTime: remaining time for the task. this is important for calculate the calendar trigger time
    func startProgress(forTask task: Task, referenceDate: Date, remainingTime: TimeInterval) {
        scheduleLocalNotification(forTask: task, withText: "You have only 10 Minutes left for your task!", referenceDate: referenceDate, remainingTime: remainingTime - (10.0 * 60.0))
        scheduleLocalNotification(forTask: task, withText: "Your time is up!", referenceDate: referenceDate, remainingTime: remainingTime)
    }
    
    /// all progress is stoppped. kill all pending notifications
    func stopProgress() {
        // kill all notifications
        resetNotifications()
    }
    

}
