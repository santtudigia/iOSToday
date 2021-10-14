//
//  EditDataCell.swift
//  Today
//
//  Created by Hyvärinen Santtu on 14.10.2021.
//

import Foundation
import UIKit

class EditDateCell: UITableViewCell {
    @IBOutlet var datePicker: UIDatePicker!
    
    func configure(date: Date) {
        datePicker.date = date
    }
}
