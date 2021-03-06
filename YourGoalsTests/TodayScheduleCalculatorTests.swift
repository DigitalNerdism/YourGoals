//
//  TodayScheduleCalculatorTests.swift
//  YourGoalsTests
//
//  Created by André Claaßen on 11.01.18.
//  Copyright © 2018 André Claaßen. All rights reserved.
//

import XCTest
@testable import YourGoals

class TodayScheduleCalculatorTests: StorageTestCase {
    
    let testDateTime = Date.dateTimeWithYear(2018, month: 01, day: 11, hour: 13, minute: 00, second: 00)
    let commitmentDate = Date.dateWithYear(2018, month: 01, day: 11)
    
    fileprivate func createTasks(infos: [TaskInfoTuple]) -> [Task] {
        let goal = super.testDataCreator.createGoalWithTasks(infos: infos)
        try! self.manager.saveContext()
        let orderManager = TaskOrderManager(manager: self.manager)
        return try! orderManager.tasksByOrder(forGoal: goal)
    }
    
    /// calculate a list of starting times
    func testCalulateStartingTimesWithoutActiveTask() {
        // setup
        let actionables = self.createTasks(infos:[
            ("Task 30 Minutes", 1, 30.0,nil , self.commitmentDate, nil, nil),
            ("Task 90 Minutes", 2, 90.0,nil , self.commitmentDate, nil, nil)
            ])
        
        // act
        let scheduleCalculator = TodayScheduleCalculator(manager: self.manager)
        let times = try! scheduleCalculator.calculateTimeInfos(forTime: self.testDateTime, actionables: actionables)
        
        // test
        XCTAssertEqual(2, times.count)
        XCTAssertEqual(ActionableTimeInfo(hour: 13, minute: 00, second: 00, remainingMinutes: 30.0, conflicting: false, fixed: false, actionable: actionables[0]), times[0])
        XCTAssertEqual(ActionableTimeInfo(hour: 13, minute: 30, second: 00, remainingMinutes: 90.0, conflicting: false, fixed: false, actionable: actionables[1]), times[1])
    }
    
    /// calculate a list of starti3ng times
    func testCalulateStartingTimesWithActiveTask() {
        // setup
        
        let actionables = self.createTasks(infos:[
            ("Task 30 Minutes", 1, 30.0,nil , self.commitmentDate, nil, nil),
            ("Task 90 Minutes", 2, 90.0,nil , self.commitmentDate, nil, nil)
            ])
        let activeTask = actionables.first!
        
        // task is progressing since 15 Minutes
        try! TaskProgressManager(manager: self.manager).startProgress(forTask: activeTask, atDate: self.testDateTime.addingTimeInterval(60.0 * 15.0 * -1.0))
        
        // act
        let scheduleCalculator = TodayScheduleCalculator(manager: self.manager)
        let times = try! scheduleCalculator.calculateTimeInfos(forTime: self.testDateTime, actionables: actionables)
        
        // test
        XCTAssertEqual(2, times.count)
        XCTAssertEqual(ActionableTimeInfo(hour: 12, minute: 45, second: 00, end: Date.timeWith(hour: 13, minute: 15, second: 00),
                                        remainingMinutes: 15.0, conflicting: false, fixed: false, actionable: actionables[0]), times[0])
        XCTAssertEqual(ActionableTimeInfo(hour: 13, minute: 15, second: 00, remainingMinutes: 90.0, conflicting: false, fixed: false, actionable: actionables[1]), times[1])
    }
    
    /// calculate a list of starting times with a fixed time in betwee
    func testCalulateStartingTimesWithFixedBeginTime() {
        // setup
        let actionables = self.createTasks(infos:[
            ("Task 30 Minutes", 1, 30.0,nil , self.commitmentDate, nil,nil),
            ("Task 90 Minutes", 2, 90.0,nil , self.commitmentDate, Date.timeWith(hour: 14, minute: 00, second: 00), nil)
            ])
        
        // act
        let scheduleCalculator = TodayScheduleCalculator(manager: self.manager)
        let times = try! scheduleCalculator.calculateTimeInfos(forTime: self.testDateTime, actionables: actionables)
        
        // test
        XCTAssertEqual(2, times.count)
        XCTAssertEqual(ActionableTimeInfo(hour: 13, minute: 00, second: 00, remainingMinutes: 30.0, conflicting: false, fixed: false, actionable: actionables[0]), times[0])
        XCTAssertEqual(ActionableTimeInfo(hour: 14, minute: 00, second: 00, remainingMinutes: 90.0, conflicting: false, fixed: true, actionable: actionables[1]), times[1])
    }
    
    /// calculate a list of starting times with a fixed time in betwee
    func testCalulateStartingTimesWithFixedBeginTimeInDanger() {
        // setup
        let actionables = self.createTasks(infos:[
            ("Task 30 Minutes", 1, 90.0,nil , self.commitmentDate, nil, nil), // going from 13:00 til 14:30
            ("Task 90 Minutes", 2, 90.0,nil , self.commitmentDate, Date.timeWith(hour: 14, minute: 00, second: 00), nil)
            ])
        
        // act
        let scheduleCalculator = TodayScheduleCalculator(manager: self.manager)
        let times = try! scheduleCalculator.calculateTimeInfos(forTime: self.testDateTime, actionables: actionables)
        
        // test
        XCTAssertEqual(2, times.count)
        XCTAssertEqual(ActionableTimeInfo(hour: 13, minute: 00, second: 00, remainingMinutes: 90.0, conflicting: false, fixed: false, actionable: actionables[0]), times[0])
        XCTAssertEqual(ActionableTimeInfo(hour: 14, minute: 00, second: 00, remainingMinutes: 90.0, conflicting: true, fixed: true, actionable: actionables[1]), times[1])
    }
}
