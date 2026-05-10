//
//  SettingsView.swift
//  MorseModem
//
//  Created by Nicolas Lhomme on 26/01/2026.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var settings: AppSettings
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Tone Frequency")
                            Spacer()
                            Text("\(Int(settings.toneFrequency)) Hz")
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $settings.toneFrequency, in: 300...1500, step: 50)
                            .accessibilityLabel("Tone Frequency")
                            .accessibilityValue("\(Int(settings.toneFrequency)) hertz")
                            .accessibilityAdjustableAction { direction in
                                switch direction {
                                case .increment: settings.toneFrequency = min(settings.toneFrequency + 50, 1500)
                                case .decrement: settings.toneFrequency = max(settings.toneFrequency - 50, 300)
                                @unknown default: break
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Speed")
                            Spacer()
                            Text("\(settings.wordsPerMinute) WPM")
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: Binding(
                            get: { Double(settings.wordsPerMinute) },
                            set: { settings.wordsPerMinute = Int($0) }
                        ), in: 5...40, step: 1)
                            .accessibilityLabel("Speed")
                            .accessibilityValue("\(settings.wordsPerMinute) words per minute")
                            .accessibilityAdjustableAction { direction in
                                switch direction {
                                case .increment: settings.wordsPerMinute = min(settings.wordsPerMinute + 1, 40)
                                case .decrement: settings.wordsPerMinute = max(settings.wordsPerMinute - 1, 5)
                                @unknown default: break
                                }
                            }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Volume")
                            Spacer()
                            Text("\(Int(settings.volume * 100))%")
                                .foregroundStyle(.secondary)
                        }
                        
                        Slider(value: $settings.volume, in: 0...1, step: 0.05)
                            .accessibilityLabel("Volume")
                            .accessibilityValue("\(Int(settings.volume * 100)) percent")
                            .accessibilityAdjustableAction { direction in
                                switch direction {
                                case .increment: settings.volume = min(settings.volume + 0.05, 1.0)
                                case .decrement: settings.volume = max(settings.volume - 0.05, 0.0)
                                @unknown default: break
                                }
                            }
                    }
                } header: {
                    Text("Audio Settings")
                } footer: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tone Frequency: Adjust the pitch of the Morse code beep (300-1500 Hz)")
                        Text("Speed: Words per minute (5-40 WPM)")
                        Text("Volume: Playback volume (0-100%)")
                    }
                    .font(.caption)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Dot Duration")
                            Spacer()
                            Text("\(settings.dotDuration, specifier: "%.3f") s")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("Dash Duration")
                            Spacer()
                            Text("\(settings.dashDuration, specifier: "%.3f") s")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("Character Gap")
                            Spacer()
                            Text("\(settings.interCharacterGap, specifier: "%.3f") s")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Text("Word Gap")
                            Spacer()
                            Text("\(settings.wordGap, specifier: "%.3f") s")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Timing Information")
                } footer: {
                    Text("Calculated based on current speed setting (WPM)")
                        .font(.caption)
                }
                
                Section {
                    Button {
                        settings.toneFrequency = 700
                        settings.wordsPerMinute = 12
                        settings.volume = 0.8
                    } label: {
                        Text("Reset to Defaults")
                            .frame(maxWidth: .infinity)
                    }
                }

                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("About", systemImage: "info.circle")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView(settings: AppSettings())
}
