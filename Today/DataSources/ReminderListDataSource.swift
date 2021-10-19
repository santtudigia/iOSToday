//
//  ReminderListDataSource.swift
//  Today
//
//  Created by Hyvärinen Santtu on 14.10.2021.
//

import UIKit

class ReminderListDataSource: NSObject {
    typealias ReminderCompletedAction = (Int) -> Void
    typealias ReminderDeletedAction = () -> Void
    
    private lazy var dateFormatter = RelativeDateTimeFormatter()
    
    enum Filter : Int {
        case today
        case future
        case all
        
        func shouldInclude(date: Date) -> Bool {
            let isInToday = Locale.current.calendar.isDateInToday(date)
            
            switch self {
                case .today:
                    return isInToday
                case .future:
                    return (date > Date()) && !isInToday
                case .all:
                    return true
            }
        }
    }
    
    private var reminderCompletedAction: ReminderCompletedAction?
    private var reminderDeletedAction: ReminderDeletedAction?
    init(reminderCompletedAction: @escaping ReminderCompletedAction, reminderDeletedAction: @escaping ReminderDeletedAction) {
        self.reminderCompletedAction = reminderCompletedAction
        self.reminderDeletedAction = reminderDeletedAction
        super.init()
    }


    
    var filter: Filter = .today
    
    var filteredReminders : [Reminder] {
        return Reminder.testData.filter { reminder in filter.shouldInclude(date: reminder.dueDate) }.sorted { reminder1, reminder2 in
            reminder1.dueDate < reminder2.dueDate
        }
    }
    
    var percentComplete : Double {
        guard filteredReminders.count > 0 else {
            return 1
        }
        
        let result : Double = filteredReminders.reduce(0) { $0 + ($1.isComplete ? 1 : 0)}
        
        return result / Double(filteredReminders.count)
    }
    
    func index(for filteredIndex: Int) -> Int {
        let filteredReminder = filteredReminders[filteredIndex]
        guard let index = Reminder.testData.firstIndex(where: { $0.id == filteredReminder.id }) else {
            fatalError("Couldn't retrieve index in source array")
        }
        return index

    }
    
    func update(_ reminder: Reminder, at row: Int) {
        Reminder.testData[index(for: row)] = reminder
    }
    
    func reminder(at row: Int) -> Reminder {
        return filteredReminders[row]
    }
    
    func add(_ reminder: Reminder) -> Int? {
        Reminder.testData.insert(reminder, at: 0)
        return filteredReminders.firstIndex(where: { $0.id == reminder.id })
    }
    
    func delete(at row: Int) {
        Reminder.testData.remove(at: index(for: row))
    }
}

extension ReminderListDataSource: UITableViewDataSource {
    static let reminderListCellIdentifier = "ReminderListCell"
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredReminders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Self.reminderListCellIdentifier, for: indexPath) as? ReminderListCell else {
            fatalError("Unable to dequeue ReminderCell")
        }
        
        let reminder = reminder(at: indexPath.row)
        let dateText = reminder.dueDateTimeText(for: filter)
        cell.configure(title: reminder.title, dateText: dateText, isDone: reminder.isComplete) {
            Reminder.testData[indexPath.row].isComplete.toggle()
            tableView.reloadRows(at: [indexPath], with: .none)
            self.reminderCompletedAction?(indexPath.row)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        guard editingStyle == .delete else {
            return
        }

        delete(at: indexPath.row)
        tableView.performBatchUpdates({
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }) { (_) in
            tableView.reloadData()
        }
        
        reminderDeletedAction?()
    }
}

extension Reminder {
    static let timeFormatter : DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.dateStyle = .none
        
        return timeFormatter
    }()
    
    static let futureDateFormatter : DateFormatter = {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .medium
        timeFormatter.dateStyle = .short
        
        return timeFormatter
    }()
    
    static let todayDateFormatter: DateFormatter = {

         let format = NSLocalizedString("'Today at '%@", comment: "format string for dates occurring today")
         let dateFormatter = DateFormatter()
         dateFormatter.dateFormat = String(format: format, "hh:mm a")
         return dateFormatter
     }()
    
    func dueDateTimeText(for filter: ReminderListDataSource.Filter) -> String {
        let isInToday = Locale.current.calendar.isDateInToday(dueDate)
        
        switch filter {
            case .today:
                return Self.timeFormatter.string(from: dueDate)
            case .future:
                return Self.futureDateFormatter.string(from: dueDate)
            case .all:
                if isInToday {
                    return Self.todayDateFormatter.string(from: dueDate)
                } else {
                    return Self.futureDateFormatter.string(from: dueDate)
                }
        }
    }
}


