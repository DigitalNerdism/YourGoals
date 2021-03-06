//
//  ActionableTableCell.swift
//  YourGoals
//
//  Created by André Claaßen on 26.10.17.
//  Copyright © 2017 André Claaßen. All rights reserved.
//

import UIKit
import MGSwipeTableCell

/// a table cell for displaying habits or tasks. experimental
class ActiveLifeTableCell: MGSwipeTableCell, ActionableCell {
    @IBOutlet weak var checkBoxButton: UIButton!
    @IBOutlet weak var startingTimeLabel: UILabel!
    @IBOutlet weak var taskDescriptionLabel: UILabel!
    @IBOutlet weak var goalDescriptionLabel: UILabel!
    @IBOutlet weak var progressView: UIView!
    @IBOutlet weak var remainingTimeLabel: UILabel!
    @IBOutlet weak var remainingTimeProgressLabel: UILabel!
    @IBOutlet weak var pieProgressView: PieProgressView!
    @IBOutlet weak var progressViewHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var urlButton: UIButton!
    @IBOutlet weak var attachedImageView: UIImageView!
    
    var item: ActionableItem!
    var delegateTaskCell: ActionableTableCellDelegate!
    let colorCalculator = ColorCalculator(colors: [UIColor.red, UIColor.yellow, UIColor.green])
    var taskProgressManager:TaskProgressManager!
    var defaultProgressViewHeight:CGFloat = 0.0
    
    var swipeTableCell: MGSwipeTableCell {
        return self
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        defaultProgressViewHeight = progressViewHeightConstraint.constant
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    // MARK: - Factory Method
    
    internal static func dequeue(fromTableView tableView: UITableView, atIndexPath indexPath: IndexPath) -> ActiveLifeTableCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ActiveLifeTableCell", for: indexPath) as? ActiveLifeTableCell else {
            fatalError("*** Failed to dequeue ActiveLifeTableCell ***")
        }
        
        return cell
    }
    
    @IBAction func checkBoxAction(_ sender: Any) {
        delegateTaskCell.actionableStateChangeDesired(item: self.item)
    }
     
    @IBAction func clickOnURL(_ sender: Any) {
        
        guard let urlString = self.item.actionable.urlString else {
            NSLog("clickOnURL failed. no URL is set")
            return
        }
        
        guard let url = URL(string: urlString) else {
            NSLog("clickOnURL failed: string is not an url")
            return
        }
        
        UIApplication.shared.open(url)
    }
    
    // MARK: - Content
    
    /// show the time info state in the checkbox button
    ///
    /// - Parameter state: .active or .done
    func showButtonState(_ state: ActionableTimeInfo.State) {
        var imageAsset:ImageAsset!
        switch state {
        case .progressing, .open:
            imageAsset = Asset.taskCircle
        case .done:
            imageAsset = Asset.taskChecked
        case .progress:
            imageAsset = Asset.taskProgress
        }
        
        self.checkBoxButton.setImage(imageAsset.image, for: .normal)
    }
    
    /// show the task progress state and resize the control for the needed height
    ///
    /// - Parameter date: show progress for date
    func showTaskProgress(timeInfo: ActionableTimeInfo, forDate date: Date) {
        let isProgressing = timeInfo.state(forDate: date) == .progressing
        self.progressView.isHidden = !isProgressing
        self.progressViewHeightConstraint.constant = isProgressing ? defaultProgressViewHeight : 0.0
        if isProgressing {
            let remainingPercentage = CGFloat(timeInfo.actionable.calcRemainingPercentage(atDate: date))
            let progressColor = self.colorCalculator.calculateColor(percent: remainingPercentage)
            if let imageData = timeInfo.actionable.imageData {
                self.contentView.backgroundColor = UIColor.white
                self.attachedImageView.image = UIImage(data: imageData)
            } else {
                self.attachedImageView.image = nil
                self.contentView.backgroundColor = progressColor.lighter(by: 75.0)
            }
            self.remainingTimeProgressLabel.text =  timeInfo.actionable.calcRemainingTimeInterval(atDate: date).formattedAsString()
            self.pieProgressView.progress = 1.0 - remainingPercentage
            self.pieProgressView.progressTintColor = progressColor.darker()
            self.pieProgressView.fillColor = UIColor.clear
            self.pieProgressView.trackTintColor = progressColor.darker()
            self.pieProgressView.clockwise = true
        } else {
            self.contentView.backgroundColor = UIColor.white
        }
    }
    
    /// quick :hack: to change the progress of a task.
    ///
    /// - Parameter sender: self
    @IBAction func timerPlusTouched(_ sender: Any) {
        let progressingDate = Date()
        let timeInfo = self.item as! ActionableTimeInfo
        try? self.taskProgressManager.changeTaskSize(forTask: timeInfo.actionable, delta: 15.0, forDate: progressingDate)
        showTaskProgress(timeInfo: timeInfo, forDate: progressingDate)
    }
    
    /// show the working time on this task.
    ///
    /// - Parameter task: task
    func showWorkingTime(timeInfo: ActionableTimeInfo, forDate date: Date) {
        let tuple = TaskWorkingTimeTextCreator().timeLabelsForActiveLife(timeInfo: timeInfo, forDate: date)
        self.startingTimeLabel.text = tuple.startingTimeText
        let workingTimeTextColor = timeInfo.conflicting ? UIColor.red : timeInfo.fixedStartingTime ? UIColor.blue : UIColor.black
        self.remainingTimeLabel.text = tuple.remainingTimeInMinutes
        self.startingTimeLabel.textColor = workingTimeTextColor
        self.remainingTimeProgressLabel.text = tuple.remainingTime
    }
    
    /// adapt cell ui for a habit or a task
    ///
    /// - Parameter type: the type of the actionable
    func adaptUI(forActionableType type: ActionableType) {
        switch type {
        case .habit:
            checkBoxButton.setImage(Asset.habitBox.image, for: .normal)
            checkBoxButton.setImage(Asset.habitBoxChecked.image, for: .selected)
        case .task:
            checkBoxButton.setImage(Asset.taskCircle.image, for: .normal)
            checkBoxButton.setImage(Asset.taskChecked.image, for: .selected)
        }
    }
    
    /// show the attached url as a clickable button
    ///
    /// - Parameter url: url
    func showAttachedURL(url: String?) {
        guard let url = url else {
            self.urlButton.isHidden = true
            return
        }
        
        self.urlButton.isHidden = false
        self.urlButton.setTitle(url, for: .normal)
    }
    
    /// show the attached image as a transparent image background
    ///
    /// - Parameter data: image data
    func showAttachedImage(imageData data: Data?) {
        guard let data = data else {
            self.attachedImageView.image = nil
            self.attachedImageView.isHidden = true
            return
        }
        
        self.attachedImageView.image = UIImage(data: data)
        self.attachedImageView.isHidden = false
        self.attachedImageView.contentMode = .scaleAspectFill
        self.clipsToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.attachedImageView.frame = CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height)
    }
    
    fileprivate func showGoalInfo(timeInfo: ActionableTimeInfo) {
        if let goalName = timeInfo.actionable.goal?.name {
            goalDescriptionLabel.text = "Goal: \(goalName)"
            goalDescriptionLabel.isHidden = false
        } else {
            goalDescriptionLabel.isHidden = true
        }
    }
    
    /// show the content of the task in this cell
    ///
    /// - Parameters:
    ///   - manager: the storage manager
    ///   - theme: Color theme for this cell
    ///   - actionable: show the actionable in the cell
    ///   - date: for this date
    ///   - delegate: a delegate for call back actions
    func configure(manager: GoalsStorageManager,
                   theme: Theme,
                   item: ActionableItem,
                   forDate date: Date,
                   delegate: ActionableTableCellDelegate) {
        let timeInfo = item as! ActionableTimeInfo
        self.taskProgressManager = TaskProgressManager(manager: manager)
        self.item = timeInfo
        self.delegateTaskCell = delegate
        self.taskDescriptionLabel.sizeToFit()
        adaptUI(forActionableType: timeInfo.actionable.type)
        showButtonState(timeInfo.state(forDate: date))
        showTaskProgress(timeInfo: timeInfo, forDate: date)
        showWorkingTime(timeInfo: timeInfo, forDate: date)
        showAttachedURL(url: timeInfo.actionable.urlString)
        showAttachedImage(imageData: timeInfo.actionable.imageData)
        taskDescriptionLabel.text = timeInfo.actionable.name
        showGoalInfo(timeInfo: timeInfo)
    }
}
