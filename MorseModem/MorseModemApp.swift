//
//  MorseModemApp.swift
//  MorseModem
//
//  Created by Nicolas Lhomme on 26/01/2026.
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
                    // Handle incoming shared audio files
                    print("📥 Received URL: \(url)")
                    print("📥 URL scheme: \(url.scheme ?? "none")")
                    print("📥 URL path: \(url.path)")
                    print("📥 Is file URL: \(url.isFileURL)")
                    
                    // Don't access security-scoped resource here
                    // Let the DecoderViewModel handle it
                    sharedAudioURL = url
                    print("✅ URL passed to ContentView")
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
