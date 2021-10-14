//
//  EditTitleCell.swift
//  Today
//
//  Created by Hyvärinen Santtu on 14.10.2021.
//

import Foundation
import UIKit

class EditTitleCell: UITableViewCell {
    @IBOutlet var titleTextField: UITextField!
    
    func configure(title: String) {
        titleTextField.text = title
    }
}
