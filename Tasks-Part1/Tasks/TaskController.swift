//
//  TaskController.swift
//  Tasks
//
//  Created by Thomas Cacciatore on 1/29/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import Foundation
import CoreData


let baseURL = URL(string: "https://tasks-3f211.firebaseio.com/")!

class TaskController {
    
    typealias CompletionHandler = (Error?) -> Void
    
    init() {
        fetchTasksFromServer()
    }
    
    func fetchTasksFromServer(completion: @escaping CompletionHandler = { _ in }) {
        let requestURL = baseURL.appendingPathExtension("json")
        
        URLSession.shared.dataTask(with: requestURL) { (data, _, error) in
            if let error = error {
                print("Error fetching tasks: \(error)")
                DispatchQueue.main.async {
                    completion(error)
                }
            }
            guard let data = data else {
                print("No data returned by data task")
                DispatchQueue.main.async {
                    completion(NSError())
                }
                return
            }
            
            do {
                let taskRepresentations = Array(try JSONDecoder().decode([String : TaskRepresentation].self, from: data).values)
                
                try self.updateTasks(with: taskRepresentations)
                DispatchQueue.main.async {
                    completion(nil)
                }
            } catch {
                print("Error decoding or storing task representations: \(error)")
                DispatchQueue.main.async {
                    completion(error)
                }
            }
        }.resume()
    }
    
    func sendTasksToServer(task: Task, completion: @escaping CompletionHandler = { _ in }) {
        let uuid = task.identifier ?? UUID()
        let requestURL = baseURL.appendingPathComponent(uuid.uuidString).appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "PUT"
        
        do {
            guard var representation = task.taskRepresentation else {
                completion(NSError())
                return
            }
            representation.identifier = uuid.uuidString
            task.identifier = uuid
            try CoreDataStack.shared.save()
            request.httpBody = try JSONEncoder().encode(representation)
        } catch {
            print("Error encoding task \(task): \(error)")
            DispatchQueue.main.async {
                completion(error)
            }
            return
        }
        
        URLSession.shared.dataTask(with: request) { ( _, _, error) in
            if let error = error {
                print("Error PUTting task to sercer: \(error)")
                DispatchQueue.main.async {
                    completion(error)
                }
                return
            }
            DispatchQueue.main.async {
                completion(nil)
            }
        }.resume()
    }
    
    func deleteTaskFromServer(_ task: Task, completion: @escaping CompletionHandler = { _ in }) {
        guard let uuid = task.identifier else {
            completion(NSError())
            return
        }
        let requestURL = baseURL.appendingPathComponent(uuid.uuidString).appendingPathExtension("json")
        var request = URLRequest(url: requestURL)
        request.httpMethod = "DELETE"
        
        URLSession.shared.dataTask(with: request) { (_, response, error) in
            print(response!)
            DispatchQueue.main.async {
                completion(error)
            }
        }.resume()
        
    }
    private func updateTasks(with representations:[TaskRepresentation]) throws {
        let tasksWithID = representations.filter { $0.identifier != nil }
        let identifiersToFetch = tasksWithID.compactMap { UUID(uuidString: $0.identifier!) }
        let representationsByID = Dictionary(uniqueKeysWithValues: zip(identifiersToFetch, tasksWithID))
        var tasksToCreate = representationsByID
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "identifier IN %@", identifiersToFetch)
        
        let context = CoreDataStack.shared.container.newBackgroundContext()
        
        context.perform {
            do {
                let existingTasks = try context.fetch(fetchRequest)
                for task in existingTasks {
                    guard let id = task.identifier,
                        let representation = representationsByID[id] else { continue }
                    self.update(task: task, with: representation)
                    tasksToCreate.removeValue(forKey: id)
                }
                
                for representation in tasksToCreate.values {
                    Task(taskRepresentation: representation, context: context)
                }
            } catch {
                print("Error fetching tasks for UUIDs: \(error)")
            }
        }
        
        try CoreDataStack.shared.save(context: context)
    }
    private func update(task: Task, with representation: TaskRepresentation) {
        task.name = representation.name
        task.notes = representation.notes
        task.priority = representation.priority
    }
}
