//
//  FitGeniusApp.swift
//  FitGenius
//
//  Created by Cesia Flores on 1/27/25.
//

import SwiftUI
import SwiftData
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

// Main entry point of the FitGenius application
@main
struct FitGeniusApp: App {
    @StateObject private var workoutManager = WorkoutPlanManager()
    @StateObject var healthManager = HealthManager()
    @StateObject private var currentUser = CurrentUser.shared
    
    // Configures Firebase when the app launches
    init() {
        FirebaseApp.configure()
    }
    
    // Container for local data storage (used by SwiftData)
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
    
    // Determines the root view depending on whether the user is authenticated
    var body: some Scene {
        WindowGroup {

            if Auth.auth().currentUser == nil {
                
                AuthView() // Show login/signup screen if user is NOT logged in
                    .environmentObject(currentUser)
                    .environmentObject(workoutManager)
            } else {
                MainView() // Loads the main view
                    .environmentObject(currentUser)
                    .environmentObject(workoutManager)
                    .environmentObject(healthManager)
            }

        }
        .modelContainer(sharedModelContainer)
    }
}
