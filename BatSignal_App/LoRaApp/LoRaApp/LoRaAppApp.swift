//
//  LoRaAppApp.swift
//  LoRaApp
//
//  Created by admin on 11/8/25.
//
// Entry point of app

import SwiftUI

// launches initial view
@main
struct LoRaAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// code for db functionality
struct YourAppNameApp: App {
    let persistenceController = PersistenceController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.viewContext)
        }
    }
}
