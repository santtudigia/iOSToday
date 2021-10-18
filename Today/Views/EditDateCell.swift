//
//  EditDataCell.swift
//  Today
//
//  Created by Hyvärinen Santtu on 14.10.2021.
//

import Foundation
import UIKit

class EditDateCell: UITableViewCell {
    
    typealias DateChangeAction = (Date) -> Void
    
    @IBOutlet var datePicker: UIDatePicker!
    
    var dateChangeAction : DateChangeAction?
    
    func configure(date: Date, actionChange: @escaping DateChangeAction) {
        datePicker.date = date
        self.dateChangeAction = actionChange
    }
    
    @objc
    func dateChanged(_ sender: UIDatePicker) {
        dateChangeAction?(sender.date)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        datePicker.addTarget(self, action: #selector(dateChanged(_:)), for: .valueChanged)
                             
    }
}
