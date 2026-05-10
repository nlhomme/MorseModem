//
//  EncoderView.swift
//  MorseModem
//

import SwiftUI
import SwiftData

struct EncoderView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \AppSettings.toneFrequency) private var settingsArray: [AppSettings]

    @State private var viewModel: EncoderViewModel?
    @State private var showSettings = false
    @State private var exportedFileURL: URL?
    @State private var showShareSheet = false
    @State private var showSuccessAlert = false

    private var settings: AppSettings {
        AppSettings.resolve(from: settingsArray, in: modelContext)
    }

    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Input Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Text to Encode")
                            .font(.headline)

                        TextField("Enter your message", text: Binding(
                            get: { viewModel?.inputText ?? "" },
                            set: { viewModel?.inputText = $0 }
                        ), axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(5...10)
                        .accessibilityLabel("Text input field")
                        .onChange(of: viewModel?.inputText) { oldValue, newValue in
                            viewModel?.updateMorseCode()
                        }
                        .focused($isFocused)
                        .submitLabel(.done)
                        .onChange(of: viewModel?.inputText) { oldValue, newValue in
                            guard isFocused else { return }
                            guard newValue?.contains("\n") == true else { return }
                            isFocused = false
                            viewModel?.inputText = newValue?.replacing("\n", with: "") ?? ""
                        }

                        if let text = viewModel?.inputText, !text.isEmpty {
                            Text("\(text.count) characters")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Morse Code Display
                    if let morse = viewModel?.morseCode, !morse.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Morse Code")
                                .font(.headline)

                            ScrollView(.horizontal, showsIndicators: false) {
                                Text(morse)
                                    .font(.system(.title2, design: .monospaced))
                                    .padding()
                                    .accessibilityHidden(true)
                            }
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .accessibilityHidden(true)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Controls
                    VStack(spacing: 16) {
                        // Play Button
                        Button {
                            Task {
                                if viewModel?.toneGenerator.isPlaying == true {
                                    viewModel?.stopPlaying()
                                } else {
                                    await viewModel?.playMorse(settings: settings)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: viewModel?.toneGenerator.isPlaying == true ? "stop.fill" : "play.fill")
                                Text(viewModel?.toneGenerator.isPlaying == true ? "Stop" : "Play Morse Code")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel?.morseCode.isEmpty == false ? Color.accentColor : Color.gray)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(viewModel?.morseCode.isEmpty ?? true)
                        .accessibilityLabel(viewModel?.toneGenerator.isPlaying == true ? "Stop playing" : "Play morse code")
                        .accessibilityHint(viewModel?.toneGenerator.isPlaying == true ? "Stops the audio playback" : "Plays the encoded Morse code as audio")

                        // Export Button
                        Button {
                            Task {
                                if let url = await viewModel?.exportAudio(settings: settings) {
                                    exportedFileURL = url
                                    showShareSheet = true
                                }
                            }
                        } label: {
                            HStack {
                                if viewModel?.isExporting == true {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Export Audio")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel?.morseCode.isEmpty == false ? Color.green : Color.gray)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(viewModel?.morseCode.isEmpty ?? true || viewModel?.isExporting == true)
                        .accessibilityLabel("Export audio file")
                        .accessibilityHint("Exports the Morse code as an audio file to share")

                        // Clear Button
                        Button {
                            viewModel?.clear()
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Clear")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(viewModel?.inputText.isEmpty ?? true)
                        .accessibilityHint("Clears the input text and Morse code")
                    }
                    .padding()

                    // Settings Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Settings")
                            .font(.headline)

                        HStack {
                            Label("\(Int(settings.toneFrequency)) Hz", systemImage: "waveform")
                            Spacer()
                            Label("\(settings.wordsPerMinute) WPM", systemImage: "speedometer")
                            Spacer()
                            Label("\(Int(settings.volume * 100))%", systemImage: "speaker.wave.2")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(String(localized: "Current Settings")): \(Int(settings.toneFrequency)) Hz, \(settings.wordsPerMinute) WPM, \(Int(settings.volume * 100))%")
                }
                .padding()
            }
            .navigationTitle("Encoder")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(settings: settings)
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ShareSheet(items: [url])
                }
            }
            .alert("Export Successful", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Audio file has been exported successfully.")
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = EncoderViewModel(modelContext: modelContext)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .background {
                viewModel?.stopPlaying()
            }
        }
    }
}

#Preview {
    EncoderView()
        .modelContainer(for: [AppSettings.self, Message.self], inMemory: true)
}
