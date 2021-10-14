//
//  EditNotesCell.swift
//  Today
//
//  Created by Hyvärinen Santtu on 14.10.2021.
//

import UIKit


class EditNotesCell: UITableViewCell {

    @IBOutlet var notesTextView: UITextView!

    func configure(notes: String?) {
        notesTextView.text = notes
    }
}
