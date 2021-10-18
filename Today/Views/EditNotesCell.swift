//
//  EditNotesCell.swift
//  Today
//
//  Created by Hyvärinen Santtu on 14.10.2021.
//

import UIKit


class EditNotesCell: UITableViewCell {
    typealias NotesChangeAction = (String) -> Void
    
    @IBOutlet var notesTextView: UITextView!

    private var notesChangeAction: NotesChangeAction?
    
    func configure(notes: String?, changeAction: NotesChangeAction?) {
        notesTextView.text = notes
        self.notesChangeAction = changeAction
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        notesTextView.delegate = self
    }
}

extension EditNotesCell: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if let originalText = textView.text {
            let title = (originalText as NSString).replacingCharacters(in: range, with: text)
            notesChangeAction?(title)
        }

        return true

    }

}
