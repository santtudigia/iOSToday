//
//  ReminderListCell.swift
//  Today
//
//  Created by Hyvärinen Santtu on 14.10.2021.
//

import UIKit

class ReminderListCell: UITableViewCell{
    
    typealias DoneButtonAction = () -> Void
 
    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var doneButton: UIButton!
    
    @IBOutlet var dateLabel: UILabel!
    
    private var doneButtonAction: DoneButtonAction?

    
    @IBAction func doneButtonTriggered(_ sender: UIButton) {
        doneButtonAction?()
    }
    
    func configure(title: String, dateText: String, isDone : Bool, doneButtonAction: @escaping DoneButtonAction) {
        titleLabel.text = title
        dateLabel.text = dateText
        
        let image = isDone ? UIImage(systemName: "circle.fill") : UIImage(systemName: "circle")
        doneButton.setBackgroundImage(image, for: .normal)
        
        self.doneButtonAction = doneButtonAction
    }
}
