//
//  MorseModemApp.swift
//  MorseModem
//

import SwiftUI
import SwiftData

@main
struct MorseModemApp: App {
    @State private var sharedAudioURL: URL?
    @State private var showSplash = true

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
            ZStack {
                ContentView(sharedAudioURL: $sharedAudioURL)
                    .onOpenURL { url in
                        sharedAudioURL = url
                    }

                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showSplash = false
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
