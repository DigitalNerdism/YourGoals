//
//  ProtocolTableViewController.swift
//  YourGoals
//
//  Created by André Claaßen on 14.06.18.
//  Copyright © 2018 André Claaßen. All rights reserved.
//

import UIKit

/// a structured table view controller for displaying the history of achieved habits, tasks, and goals.
class ProtocolTableViewController: UITableViewController, TaskNotificationProviderProtocol {
    
    /// the core data storage manager
    var manager:GoalsStorageManager!
    
    /// the history of goals, where tasks or habits are achieved. the goals are building the section headers
    var protocolGoalInfos = [ProtocolGoalInfo]()
    
    /// vor every goal you have a protocol of achieved items
    var protocolHistory = [[ProtocolProgressInfo]]()
    
    /// reload the protocol state from the storage (inefficient)
    func reloadProtocolHistory() {
        do {
            let protocolDataSource = ProtocolDataSource(manager: self.manager, backburnedGoals: SettingsUserDefault.standard.backburnedGoals )
            protocolGoalInfos = try protocolDataSource.fetchWorkedGoals(forDate: Date())
            for goalInfo in protocolGoalInfos {
                let protocolProgressInfos = try protocolDataSource.fetchProgressOnGoal(goalInfo: goalInfo)
                protocolHistory.append(protocolProgressInfos)
            }
            self.tableView.reloadData()
        }
        catch let error {
            self.showNotification(forError: error)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.manager = GoalsStorageManager.defaultStorageManager
        self.tableView.registerReusableCell(ProtocolTableViewCell.self)
        let nib = UINib(nibName: "ProtocolSectionView", bundle: nil)
        self.tableView.register(nib, forHeaderFooterViewReuseIdentifier: "ProtocolSectionView")
        TaskNotificationObserver.defaultObserver.register(provider: self)
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    override func viewWillAppear(_ animated: Bool) {
        reloadProtocolHistory()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    /// retrieve the number of goals on which you work on the actual day
    override func numberOfSections(in tableView: UITableView) -> Int {
        return protocolGoalInfos.count
    }
    
    /// retrieve the number of history items where you worked on
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return protocolHistory[section].count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let date = Date()
        let protocolCell = ProtocolTableViewCell.dequeue(fromTableView: self.tableView, atIndexPath: indexPath)
        let protocolInfo = protocolHistory[indexPath.section][indexPath.row]
        protocolCell.configure(protocolInfo: protocolInfo, onDate: date)
        return protocolCell
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let protocolSectionView = self.tableView.dequeueReusableHeaderFooterView(withIdentifier: "ProtocolSectionView") as! ProtocolSectionView
        let date = Date()
        let protocolGoalInfo = self.protocolGoalInfos[section]
        do {
            try protocolSectionView.configure(manager: self.manager, backburnedGoals: SettingsUserDefault.standard.backburnedGoals, goalInfo: protocolGoalInfo)
        }
        catch let error {
            self.showNotification(forError: error)
        }
        
        return protocolSectionView
    }
    
    /// calculate the size of the header for the protocol
    ///
    /// - Parameters:
    ///   - tableView: the protocol table view
    ///   - section: the section number (will be ignored)
    /// - Returns: the  size of the section
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 138.0
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - TaskProviderProtocol
    
    func progressStarted(forTask task: Task, referenceTime: Date) {
        self.reloadProtocolHistory()
    }
    
    func progressChanged(forTask task: Task, referenceTime: Date) {
        self.reloadProtocolHistory()
    }
    
    func progressStopped() {
        self.reloadProtocolHistory()
    }
    
    func tasksChanged() {
        self.reloadProtocolHistory()
    }
}
