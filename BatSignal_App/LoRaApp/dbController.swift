//
//  dbController.swift
//  LoRaApp
//
//  Created by admin on 11/13/25.
//
// Core Data setup - Load DB
// sets up and manages the core data

import Foundation

import CoreData

struct PersistenceController {
    // create one instance for entire app
    static let shared = PersistenceController()
    
    // container that holds database
    let container: NSPersistentContainer
    
    init() {
        // load database file
        container = NSPersistentContainer(name: "rssi_db")
        
        // open/ create db file on disk
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Core Data failed to load: \(error.localizedDescription)")
            }
        }
    }
    
    // workspace where you read/write data
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
}
