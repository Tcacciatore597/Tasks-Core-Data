//
//  TaskRepresentation.swift
//  Tasks
//
//  Created by Thomas Cacciatore on 1/29/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import Foundation

struct TaskRepresentation: Codable {
    var identifier: String?
    var name: String
    var notes: String?
    var priority: String
}
