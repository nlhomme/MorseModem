//
//  MorseModemApp.swift
//  MorseModem
//

import SwiftUI
import SwiftData

@main
struct MorseModemApp: App {
    @State private var sharedAudioURL: URL?

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Message.self,
            AppSettings.self,
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
            ContentView(sharedAudioURL: $sharedAudioURL)
                .onOpenURL { url in
                    sharedAudioURL = url
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
