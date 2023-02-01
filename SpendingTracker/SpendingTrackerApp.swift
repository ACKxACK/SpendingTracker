//
//  SpendingTrackerApp.swift
//  SpendingTracker
//
//  Created by Ali Can Kayaaslan on 1.02.2023.
//

import SwiftUI

@main
struct SpendingTrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
