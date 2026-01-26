//
//  ReferenceView.swift
//  MorseModem
//
//  Created by Nicolas Lhomme on 26/01/2026.
//

import SwiftUI
import SwiftData

struct ReferenceView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AppSettings.toneFrequency) private var settingsArray: [AppSettings]
    
    @State private var searchText = ""
    @State private var toneGenerator = ToneGenerator()
    @State private var playingCharacter: Character?
    
    private var settings: AppSettings {
        if let existing = settingsArray.first {
            return existing
        } else {
            let newSettings = AppSettings()
            modelContext.insert(newSettings)
            try? modelContext.save()
            return newSettings
        }
    }
    
    private var allCharacters: [(category: String, characters: [(char: Character, morse: String)])] {
        MorseCodeMap.allCharacters()
    }
    
    private var filteredCharacters: [(category: String, characters: [(char: Character, morse: String)])] {
        if searchText.isEmpty {
            return allCharacters
        }
        
        return allCharacters.compactMap { category in
            let filtered = category.characters.filter { char in
                String(char.char).localizedCaseInsensitiveContains(searchText) ||
                char.morse.contains(searchText)
            }
            
            return filtered.isEmpty ? nil : (category.category, filtered)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredCharacters, id: \.category) { section in
                    Section(section.category) {
                        ForEach(section.characters, id: \.char) { item in
                            HStack {
                                Text(String(item.char))
                                    .font(.title2)
                                    .frame(width: 40)
                                
                                Text(item.morse)
                                    .font(.system(.title3, design: .monospaced))
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Button {
                                    playCharacter(item.char, morse: item.morse)
                                } label: {
                                    Image(systemName: playingCharacter == item.char ? "stop.circle.fill" : "play.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(playingCharacter == item.char ? .red : .accentColor)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel("Play morse code for \(String(item.char))")
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
            }
            .navigationTitle("Morse Reference")
            .searchable(text: $searchText, prompt: "Search characters")
            .overlay {
                if filteredCharacters.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
        }
    }
    
    private func playCharacter(_ char: Character, morse: String) {
        if playingCharacter == char {
            toneGenerator.stop()
            playingCharacter = nil
        } else {
            playingCharacter = char
            
            Task {
                await toneGenerator.playMorse(morse, settings: settings)
                playingCharacter = nil
            }
        }
    }
}

#Preview {
    ReferenceView()
        .modelContainer(for: AppSettings.self, inMemory: true)
}
