//
//  ViewController.swift
//  Today
//
//  Created by Hyvärinen Santtu on 13.10.2021.
//

import UIKit

class ReminderListViewController: UITableViewController {
    
    private var reminderListDataSource: ReminderListDataSource?
    
    static let showDetailSegueIdentifier = "ShowReminderDetailSegue"
    
    override func viewDidLoad() {
        reminderListDataSource = ReminderListDataSource()
        tableView.dataSource = reminderListDataSource
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == Self.showDetailSegueIdentifier),
          let destination = segue.destination as? ReminderDetailViewController,
          let cell = sender as? UITableViewCell,
          let indexPath = tableView.indexPath(for: cell) {
            let reminder = Reminder.testData[indexPath.row]
            destination.configure(with: reminder)
        }
    }

}
