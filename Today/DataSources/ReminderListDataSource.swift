//
//  ReminderListDataSource.swift
//  Today
//
//  Created by Hyvärinen Santtu on 14.10.2021.
//

import UIKit
import EventKit

class ReminderListDataSource: NSObject {
    typealias ReminderCompletedAction = (Int) -> Void
    typealias ReminderDeletedAction = () -> Void
    typealias RemindersChangedAction = () -> Void
    
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
    
    private let eventStore = EKEventStore()
    
    private var reminders: [Reminder] = []
    private var reminderCompletedAction: ReminderCompletedAction?
    private var reminderDeletedAction: ReminderDeletedAction?
    private var remindersChangedAction: RemindersChangedAction?
    init(reminderCompletedAction: @escaping ReminderCompletedAction, reminderDeletedAction: @escaping ReminderDeletedAction,
        remindersChangedAction: @escaping RemindersChangedAction) {
        self.reminderCompletedAction = reminderCompletedAction
        self.reminderDeletedAction = reminderDeletedAction
        self.remindersChangedAction = remindersChangedAction
        super.init()
        
        requestAccess { (authorized) in
            if authorized {
                self.readAllReminders()
                NotificationCenter.default.addObserver(self, selector: #selector(self.storeChanged(_:)), name: .EKEventStoreChanged, object: self.eventStore)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .EKEventStoreChanged, object: self.eventStore)
    }


    
    var filter: Filter = .today
    
    var filteredReminders : [Reminder] {
        return reminders.filter { reminder in filter.shouldInclude(date: reminder.dueDate) }.sorted { reminder1, reminder2 in
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
        guard let index = reminders.firstIndex(where: { $0.id == filteredReminder.id }) else {
            fatalError("Couldn't retrieve index in source array")
        }
        return index

    }
    
    func update(_ reminder: Reminder, at row: Int, completion: (Bool) -> Void) {
        saveReminder(reminder) { (id) in
            let success = id != nil
            if success {
                let index = self.index(for: row)
                reminders[index] = reminder
            }
            completion(success)
        }
    }
    
    func reminder(at row: Int) -> Reminder {
        return filteredReminders[row]
    }
    
    func add(_ reminder: Reminder, completion: (Int?) -> Void) {
        saveReminder(reminder) { (id) in
            if let id = id {
                let reminder = Reminder(id: id,
                                        title: reminder.title,
                                        dueDate: reminder.dueDate,
                                        notes: reminder.notes,
                                        isComplete: reminder.isComplete)
                reminders.insert(reminder, at: 0)
                
                let index = filteredReminders.firstIndex { $0.id == id }
                completion(index)
            } else {
                completion(nil)
            }
        }
    }
    
    func delete(at row: Int, completion: (Bool) -> Void) {
        let index = self.index(for: row)
        let reminder = reminders[index]
        
        deleteReminder(with: reminder.id, completion: { success in
            if success {
                reminders.remove(at: index)
            }
            completion(success)
        })
    }
    
    @objc
    func storeChanged(_ notification: NSNotification) {
        requestAccess { authorized in
            if authorized {
                self.readAllReminders()
            }
            
        }
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
        
        let currentReminder = reminder(at: indexPath.row)
        let dateText = currentReminder.dueDateTimeText(for: filter)

        
        cell.configure(title: currentReminder.title, dateText: dateText, isDone: currentReminder.isComplete) {
            var modifiedReminder = currentReminder
            modifiedReminder.isComplete.toggle()
            self.update(modifiedReminder, at: indexPath.row) { success in
                if success {
                    self.reminderCompletedAction?(indexPath.row)
                }
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        guard editingStyle == .delete else {
            return
        }

        delete(at: indexPath.row) { success in
            if success {
                DispatchQueue.main.async {
                    tableView.performBatchUpdates({
                        tableView.deleteRows(at: [indexPath], with: .automatic)
                    }) { (_) in
                        tableView.reloadData()
                    }
                }
                
                reminderDeletedAction?()
            }
        }
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

extension ReminderListDataSource {
    private var isEventsAvailable: Bool {
        EKEventStore.authorizationStatus(for: .reminder) == .authorized
    }
    
    func requestAccess(completion: @escaping (Bool) -> Void) {
        let currentStatus = EKEventStore.authorizationStatus(for: .reminder)
        
        guard currentStatus == .notDetermined else {
            completion(currentStatus == .authorized)
            return
        }
        
        eventStore.requestAccess(to: .reminder) { (success, error) in
            completion(success)
        }
    }
    
    private func readAllReminders() {
        guard isEventsAvailable else { return }
        
        let predicate = eventStore.predicateForReminders(in: nil)
        eventStore.fetchReminders(matching: predicate, completion: { (reminders) in
            guard let reminders = reminders else {
                self.reminders = []
                return
            }
                
            self.reminders = reminders.compactMap {
                guard let dueDate = $0.alarms?.first?.absoluteDate else {
                    return nil
                }
                    
                let reminder = Reminder(
                    id: $0.calendarItemIdentifier,
                    title: $0.title,
                    dueDate: dueDate,
                    notes: $0.notes,
                    isComplete: $0.isCompleted
                )
                    
                return reminder
            }
            self.remindersChangedAction?()
        })
    }
    
    private func readReminder(with id: String, completion: (EKReminder?) -> Void) {
        guard isEventsAvailable else {
            completion(nil)
            return
        }
        
        guard let calendarItem = eventStore.calendarItem(withIdentifier: id),
              let ekReminder = calendarItem as? EKReminder else {
                  completion(nil)
                  return
              }
        
        completion(ekReminder)
    }
    
    private func saveReminder(_ reminder: Reminder, completion: (String?) -> Void) {
        guard isEventsAvailable else {
            completion(nil)
            return
        }
        
        readReminder(with: reminder.id, completion: { (ekReminder) in
            let ekReminder = ekReminder ?? EKReminder(eventStore: self.eventStore)
            ekReminder.title = reminder.title
            ekReminder.notes = reminder.notes
            ekReminder.isCompleted = reminder.isComplete
            ekReminder.calendar = self.eventStore.defaultCalendarForNewReminders()
            ekReminder.alarms?.forEach { alarm in

                if let absoluteDate = alarm.absoluteDate {
                    let comparison = Locale.current.calendar.compare(reminder.dueDate, to: absoluteDate, toGranularity: .minute)
                    if comparison != .orderedSame {
                        ekReminder.removeAlarm(alarm)
                    }
                }
            }
            
            if !ekReminder.hasAlarms {
                ekReminder.addAlarm(EKAlarm(absoluteDate: reminder.dueDate))
            }
            
            do {
                try self.eventStore.save(ekReminder, commit: true)
                completion(ekReminder.calendarItemIdentifier)
            } catch {
                completion(nil)
            }
        })
    }
    
    private func deleteReminder(with id : String, completion: (Bool) -> Void) {
        guard isEventsAvailable else {
            completion(false)
            return
        }
        
        readReminder(with: id, completion: { (ekReminder) in
            if let ekReminder = ekReminder {
                do {
                    try self.eventStore.remove(ekReminder, commit: true)
                    completion(true)
                } catch {
                    completion(false)
                }
            }
        })
    }
}
