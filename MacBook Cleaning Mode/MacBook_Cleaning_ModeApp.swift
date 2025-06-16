//
//  MacBook_Cleaning_ModeApp.swift
//  MacBook Cleaning Mode
//
//  Created by Tariq Shafiq on 6/16/25.
//

import SwiftUI

@main
struct MacBook_Cleaning_ModeApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
