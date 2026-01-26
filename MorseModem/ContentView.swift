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
    
    var body: some View {
        TabView {
            EncoderView()
                .tabItem {
                    Label("Encoder", systemImage: "waveform.circle")
                }
            
            DecoderView()
                .tabItem {
                    Label("Decoder", systemImage: "waveform.circle.fill")
                }
            
            ReferenceView()
                .tabItem {
                    Label("Reference", systemImage: "book.circle")
                }
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock")
                }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Message.self, AppSettings.self], inMemory: true)
}
