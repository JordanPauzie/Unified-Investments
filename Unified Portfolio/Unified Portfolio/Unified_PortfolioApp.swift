//
//  Unified_PortfolioApp.swift
//  Unified Portfolio
//
//  Created by Jordan Pauzie on 7/21/25.
//

import SwiftUI
import SwiftData

@main
struct Unified_PortfolioApp: App {
//    init() {
//        setenv("PYTHON_LIBRARY", "/Library/Frameworks/Python.framework/Versions/3.13/lib/libpython3.13.dylib", 1)
//        PythonLibrary.useVersion(3, 13)
//    }
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
