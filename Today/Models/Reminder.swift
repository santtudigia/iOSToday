//
//  Reminder.swift
//  Today
//
//  Created by Hyvärinen Santtu on 14.10.2021.
//

import Foundation

struct Reminder {
    var id: String
    var title: String
    var dueDate: Date
    var notes: String? = nil
    var isComplete: Bool = false
}
