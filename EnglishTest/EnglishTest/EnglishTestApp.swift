//
//  EnglishTestApp.swift
//  EnglishTest
//
//  Created by 赵子源 on 2025/1/27.
//

import SwiftUI

@main
struct EnglishTestApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
