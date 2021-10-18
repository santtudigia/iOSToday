//
//  EditTitleCell.swift
//  Today
//
//  Created by Hyvärinen Santtu on 14.10.2021.
//

import Foundation
import UIKit

class EditTitleCell: UITableViewCell {
    typealias TitleChangeAction = (String) -> Void
    
    @IBOutlet var titleTextField: UITextField!
    
    private var titleChangeAction: TitleChangeAction?
    
    func configure(title: String, changeAction: @escaping TitleChangeAction) {
        titleTextField.text = title
        self.titleChangeAction = changeAction
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        titleTextField.delegate = self
    }
}

extension EditTitleCell: UITextFieldDelegate {

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let originalText = textField.text {
            let title = (originalText as NSString).replacingCharacters(in: range, with: string)
            titleChangeAction?(title)
        }

        return true
    }

}
