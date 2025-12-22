//
//  playgroundApp.swift
//  playground
//
//  Created by Tareq Khalili on 15/12/2025.
//

import SwiftUI
import SwiftData
import MavenCommonSwiftUI
import SDK

@main
struct playgroundApp: App {
    let modelContainer: ModelContainer
    @State var sdk: TheSDK
    
    init() {
        // Initialize ModelContainer (fast, synchronous)
        do {
            let schema = Schema([
                Meal.self,
                MealItem.self,
                DaySummary.self,
                WeightEntry.self
            ])
            
            // Ensure Application Support directory exists before SwiftData tries to create the store
            let fileManager = FileManager.default
            if let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            }
            
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not initialize ModelContainer: \(error)")
        }
        
        // Initialize SDK synchronously like the translate app
        // Match translate app exactly: use "app.translate-now.com" (with "app." prefix)
        let baseURL = URL(string: "https://app.translate-now.com")!
        let config = SDKConfig(
            baseURL: baseURL,
            facebook: "569790992889415", // Match translate app - they pass a Facebook app ID
            logOptions: .all, // Match translate app - use .all
            apnsHandler: { event in
                switch event {
                case let .didReceive(notification, details):
                    guard details == .appOpened else { return }
                    if let urlString = notification["webviewUrl"] as? String,
                       let url = URL(string: urlString) {
                        print("📱 Deep link received: \(url)")
                    }
                default:
                    break
                }
            }
        )
        sdk = TheSDK(config: config)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
                .environment(sdk) // Use direct environment like example app
        }
    }
}

// No custom environment key needed - using TheSDK directly as environment object
