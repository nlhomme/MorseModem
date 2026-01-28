//
//  ContentView.swift
//  MorseModem
//
//  Created by Nicolas Lhomme on 26/01/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var sharedAudioURL: URL?
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            EncoderView()
                .tabItem {
                    Label("Encoder", systemImage: "waveform.circle")
                }
                .tag(0)
            
            DecoderView(sharedAudioURL: $sharedAudioURL)
                .tabItem {
                    Label("Decoder", systemImage: "waveform.circle.fill")
                }
                .tag(1)
            
            ReferenceView()
                .tabItem {
                    Label("Reference", systemImage: "book.circle")
                }
                .tag(2)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
                .tag(3)
        }
        .onChange(of: sharedAudioURL) { oldValue, newValue in
            if newValue != nil {
                // Switch to decoder tab when a file is shared
                selectedTab = 1
            }
        }
    }
}

#Preview {
    @Previewable @State var sharedURL: URL? = nil
    ContentView(sharedAudioURL: $sharedURL)
        .modelContainer(for: [Message.self, AppSettings.self], inMemory: true)
}
