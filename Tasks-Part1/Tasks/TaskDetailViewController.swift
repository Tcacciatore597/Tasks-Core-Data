//
//  TaskDetailViewController.swift
//  Tasks
//
//  Created by Ben Gohlke on 1/27/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import UIKit

class TaskDetailViewController: UIViewController {
    
    // MARK: - Properties
    
    var task: Task?
    var taskController: TaskController?
    
    // MARK: - Outlets
    
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var priorityControl: UISegmentedControl!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if task == nil {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTask))
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if let task = task {
            guard let name = nameTextField.text,
                !name.isEmpty,
                let taskController = taskController else {
                    return
            }
            let notes = notesTextView.text
            let priorityIndex = priorityControl.selectedSegmentIndex
            let priority = TaskPriority.allPriorities[priorityIndex]
            task.priority = priority.rawValue
            task.name = name
            task.notes = notes
            taskController.sendTasksToServer(task: task)
            
            do {
                try CoreDataStack.shared.mainContext.save()
            } catch {
                NSLog("Error saving managed object context: \(error)")
            }
        }
    }

    private func updateViews() {
        guard isViewLoaded else { return }
        
        title = task?.name ?? "Create Task"
        nameTextField.text = task?.name ?? ""
        notesTextView.text = task?.notes ?? ""
        let priority: TaskPriority
        if let taskPriority = task?.priority {
            priority = TaskPriority(rawValue: taskPriority)!
        } else {
            priority = .normal
        }
        priorityControl.selectedSegmentIndex = TaskPriority.allPriorities.firstIndex(of: priority) ?? 1
    }
    
    @objc private func saveTask() {
        guard let name = nameTextField.text,
            !name.isEmpty,
            let taskController = taskController else {
                return
        }
        let notes = notesTextView.text
        let priorityIndex = priorityControl.selectedSegmentIndex
        let priority = TaskPriority.allPriorities[priorityIndex]
        let task = Task(name: name, notes: notes, priority: priority)
        taskController.sendTasksToServer(task: task)
        
        do {
            try CoreDataStack.shared.mainContext.save()
            navigationController?.dismiss(animated: true, completion: nil)
        } catch {
            NSLog("Error saving managed object context: \(error)")
        }
    }
}

