//
//  ViewController.swift
//  Today
//
//  Created by Hyvärinen Santtu on 13.10.2021.
//

import UIKit

class ReminderListViewController: UITableViewController {
    
    @IBOutlet var progressContainerView: UIView!
    @IBOutlet var percentCompleteView: UIView!
    @IBOutlet var percentIncompleteView: UIView!
    
    @IBOutlet var percentCompleteHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet var filterSegmentedControl: UISegmentedControl!
    
    private var reminderListDataSource: ReminderListDataSource?
    private var filter: ReminderListDataSource.Filter {
        return ReminderListDataSource.Filter(rawValue: filterSegmentedControl.selectedSegmentIndex) ?? .today
    }
    
    static let showDetailSegueIdentifier = "ShowReminderDetailSegue"
    static let mainStoryboardName = "Main"
    static let detailViewControllerIdentifier = "ReminderDetailViewController"
    
    override func viewDidLoad() {
        reminderListDataSource = ReminderListDataSource(reminderCompletedAction: { reminderIndex in
            self.tableView.reloadRows(at: [IndexPath(row: reminderIndex, section: 0)], with: .automatic)
            self.refreshProgressView()
        }, reminderDeletedAction: {
            self.refreshProgressView()
        })
        tableView.dataSource = reminderListDataSource
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let radius = view.bounds.size.width * 0.5 * 0.7
        progressContainerView.layer.cornerRadius = radius
        progressContainerView.layer.masksToBounds = true
        self.refreshProgressView()
        self.refreshBackground()
        
        if #available(iOS 13.0, *) {
            
            guard let navigationBar = self.navigationController?.navigationBar else {
                return
            }
            guard let toolBar = self.navigationController?.toolbar else {
                return
            }
            
            let navBarAppearance = UINavigationBarAppearance()
            navBarAppearance.configureWithTransparentBackground()
            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
            navBarAppearance.backgroundColor = UIColor.clear
            navigationBar.standardAppearance = navBarAppearance
            navigationBar.scrollEdgeAppearance = navBarAppearance
            
            let toolbarAppearance = UIToolbarAppearance()
            toolbarAppearance.configureWithTransparentBackground()
            toolbarAppearance.backgroundColor = UIColor.white
            toolBar.standardAppearance = toolbarAppearance
            toolBar.scrollEdgeAppearance = toolbarAppearance
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == Self.showDetailSegueIdentifier),
          let destination = segue.destination as? ReminderDetailViewController,
          let cell = sender as? UITableViewCell,
          let indexPath = tableView.indexPath(for: cell) {
            let rowIndex = indexPath.row
            guard let reminder = reminderListDataSource?.reminder(at: rowIndex) else {
                 fatalError("Couldn't find data source for reminder list.")
             }
            
            destination.configure(with: reminder, isNew: false, editAction: { reminder in
                self.reminderListDataSource?.update(reminder, at: rowIndex)
                self.tableView.reloadData()
                self.refreshProgressView()
            })
        }
    }

    @IBAction func addButtonPressed(_ sender: Any) {
        addReminder()
    }
    
    private func addReminder() {
        let storyboard = UIStoryboard(name: Self.mainStoryboardName, bundle: nil)
        let detailViewController: ReminderDetailViewController = storyboard.instantiateViewController(identifier: Self.detailViewControllerIdentifier)
        let reminder = Reminder(id: UUID().uuidString, title: "New Reminder", dueDate: Date())

        detailViewController.configure(with: reminder, isNew: true, addAction: { reminder in
            if let index = self.reminderListDataSource?.add(reminder) {
                self.tableView.insertRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                self.refreshProgressView()
            }
        })

        let navigationController = UINavigationController(rootViewController: detailViewController)
        present(navigationController, animated: true, completion: nil)
    }
    
    
    @IBAction func filterSegmentedControlSelected(_ sender: UISegmentedControl) {
        reminderListDataSource?.filter = filter
        tableView.reloadData()
        self.refreshProgressView()
        self.refreshBackground()
    }
    
    func refreshProgressView() {
        guard let percentComplete = reminderListDataSource?.percentComplete else {
            return
        }
        
        let totalHeight = progressContainerView.bounds.size.height
        percentCompleteHeightConstraint.constant = totalHeight * CGFloat(percentComplete)
        UIView.animate(withDuration: 0.2) {
            self.progressContainerView.layoutSubviews()
        }
    }
    
    private func refreshBackground() {

        tableView.backgroundView = nil

        let backgroundView = UIView()

        if let backgroundColors = filter.backgroundColors {
            let gradientBackgroundLayer = CAGradientLayer()
            gradientBackgroundLayer.colors = backgroundColors
            gradientBackgroundLayer.frame = tableView.frame
            backgroundView.layer.addSublayer(gradientBackgroundLayer)
        } else {
            backgroundView.backgroundColor = filter.substituteBackgroundColor
        }

        tableView.backgroundView = backgroundView

    }
}

fileprivate extension ReminderListDataSource.Filter {

    private var gradientBeginColor: UIColor? {

        switch self {
            case .today: return UIColor.magenta
            case .future: return UIColor.magenta
            case .all: return UIColor.magenta
        }

    }

    private var gradientEndColor: UIColor? {
        switch self {
            case .today: return UIColor.red
            case .future: return UIColor.red
            case .all: return UIColor.red
        }
    }

    var backgroundColors: [CGColor]? {
        guard let beginColor = gradientBeginColor, let endColor = gradientEndColor else {
            return nil
        }
        return [beginColor.cgColor, endColor.cgColor]
    }

    var substituteBackgroundColor: UIColor {
        return gradientBeginColor ?? .tertiarySystemBackground
    }

}
