//
//  DecoderView.swift
//  MorseModem
//
//  Created by Nicolas Lhomme on 26/01/2026.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct DecoderView: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var sharedAudioURL: URL?
    
    @State private var viewModel: DecoderViewModel?
    @State private var showFilePicker = false
    @State private var showCopiedAlert = false
    @State private var pendingURL: URL? // Store URL until viewModel is ready
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Import Status Indicator
                    if viewModel?.isImporting == true {
                        HStack {
                            ProgressView()
                            Text("Importing and decoding audio...")
                                .font(.headline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    }
                    
                    // Recording Controls
                    VStack(spacing: 16) {
                        // Recording Status Banner (Always visible when recording)
                        if viewModel?.isRecording == true {
                            VStack(spacing: 16) {
                                // Prominent Recording Indicator
                                HStack(spacing: 12) {
                                    ZStack {
                                        // Pulsing outer ring
                                        Circle()
                                            .stroke(Color.red.opacity(0.3), lineWidth: 4)
                                            .frame(width: 24, height: 24)
                                            .scaleEffect(viewModel?.isRecording == true ? 1.5 : 1.0)
                                            .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel?.isRecording)
                                        
                                        // Inner dot
                                        Circle()
                                            .fill(Color.red)
                                            .frame(width: 16, height: 16)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("RECORDING")
                                            .font(.headline)
                                            .fontWeight(.bold)
                                        
                                        Text("Speak or play Morse code near your device")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.red.opacity(0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.red.opacity(0.5), lineWidth: 2)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                
                                // Waveform visualization
                                if let waveform = viewModel?.waveformData, !waveform.isEmpty {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Audio Level")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        WaveformView(data: waveform)
                                            .frame(height: 80)
                                    }
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                } else {
                                    // Placeholder while waiting for audio
                                    VStack(spacing: 8) {
                                        ProgressView()
                                            .tint(.red)
                                        Text("Listening for audio...")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    .frame(height: 60)
                                    .frame(maxWidth: .infinity)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        
                        // Record Button (changes based on state)
                        Button {
                            print("🎤 Button tapped! Current isRecording: \(viewModel?.isRecording ?? false)")
                            Task {
                                if viewModel?.isRecording == true {
                                    print("🎤 Stopping recording...")
                                    viewModel?.stopRecording()
                                } else {
                                    print("🎤 Starting recording...")
                                    await viewModel?.startRecording()
                                }
                            }
                        } label: {
                            if viewModel?.isRecording == true {
                                // Recording state - show stop button with timer
                                VStack(spacing: 8) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "stop.circle.fill")
                                            .font(.title2)
                                            .imageScale(.large)
                                        
                                        Text("Stop Recording")
                                            .fontWeight(.semibold)
                                    }
                                    
                                    // Recording duration timer
                                    if let duration = viewModel?.recordingDuration {
                                        Text(formatDuration(duration))
                                            .font(.system(.body, design: .monospaced))
                                            .fontWeight(.medium)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.red)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: Color.red.opacity(0.4), radius: 12, y: 6)
                            } else {
                                // Not recording - show start button
                                HStack(spacing: 12) {
                                    Image(systemName: "mic.circle.fill")
                                        .font(.title2)
                                        .imageScale(.large)
                                    
                                    Text("Start Recording")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: Color.accentColor.opacity(0.3), radius: 8, y: 4)
                            }
                        }
                        .accessibilityLabel(viewModel?.isRecording == true ? "Stop recording" : "Start recording")
                        .disabled(viewModel?.isImporting == true)
                        
                        // Divider when recording (visual separation)
                        if viewModel?.isRecording == true {
                            HStack {
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                                Text("OR")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 1)
                            }
                            .padding(.vertical, 8)
                        }
                        
                        // Import Button
                        Button {
                            showFilePicker = true
                        } label: {
                            HStack(spacing: 12) {
                                if viewModel?.isImporting == true {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "folder.badge.plus")
                                        .font(.title3)
                                    Text("Import Audio File")
                                        .fontWeight(.medium)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(viewModel?.isImporting == true || viewModel?.isRecording == true)
                        .opacity((viewModel?.isImporting == true || viewModel?.isRecording == true) ? 0.5 : 1.0)
                        .accessibilityLabel("Import audio file")
                    }
                    .padding()
                    
                    // Decoded Morse Code
                    if let morse = viewModel?.decodedMorse, !morse.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Decoded Morse Code")
                                .font(.headline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                Text(morse)
                                    .font(.system(.title3, design: .monospaced))
                                    .padding()
                            }
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Decoded Text
                    if let text = viewModel?.decodedText, !text.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Decoded Text")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Button {
                                    viewModel?.copyToClipboard()
                                    showCopiedAlert = true
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                        .font(.caption)
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            Text(text)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.tertiarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .textSelection(.enabled)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        // Clear Button
                        Button {
                            viewModel?.clear()
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle")
                                Text("Clear Results")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal)
                    }
                    
                    // Instructions
                    if viewModel?.decodedText.isEmpty ?? true {
                        VStack(spacing: 12) {
                            Image(systemName: "waveform.circle")
                                .font(.system(size: 60))
                                .foregroundStyle(.secondary)
                            
                            Text("Decode Morse Code")
                                .font(.headline)
                            
                            Text("Record audio with your microphone or import an audio file containing Morse code.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }
                }
                .padding()
            }
            .navigationTitle("Decoder")
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.audio],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        Task {
                            await viewModel?.importAudioFile(url: url)
                        }
                    }
                case .failure(let error):
                    viewModel?.importError = error.localizedDescription
                }
            }
            .alert("Copied", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Text copied to clipboard")
            }
            .alert("Permission Required", isPresented: Binding(
                get: { viewModel?.showPermissionAlert ?? false },
                set: { viewModel?.showPermissionAlert = $0 }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Microphone access is required to record Morse code. Please enable it in Settings.")
            }
            .alert("Import Error", isPresented: Binding(
                get: { viewModel?.importError != nil },
                set: { if !$0 { viewModel?.importError = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel?.importError ?? "")
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = DecoderViewModel(modelContext: modelContext)
                
                // Process any pending URL that arrived before viewModel was ready
                if let url = pendingURL {
                    Task {
                        await viewModel?.importAudioFile(url: url)
                        pendingURL = nil
                        sharedAudioURL = nil
                    }
                }
            }
        }
        .onChange(of: sharedAudioURL) { oldValue, newValue in
            if let url = newValue {
                if let viewModel = viewModel {
                    // ViewModel is ready, process immediately
                    Task {
                        await viewModel.importAudioFile(url: url)
                        sharedAudioURL = nil
                    }
                } else {
                    // ViewModel not ready yet, store for later
                    pendingURL = url
                    sharedAudioURL = nil
                }
            }
        }
    }
    
    // Helper function to format recording duration
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        let milliseconds = Int((duration.truncatingRemainder(dividingBy: 1)) * 10)
        return String(format: "%d:%02d.%01d", minutes, seconds, milliseconds)
    }
}

// Waveform visualization view
struct WaveformView: View {
    let data: [Float]
    
    var body: some View {
        Canvas { context, size in
            let width = size.width
            let height = size.height
            let stepWidth = width / CGFloat(data.count)
            
            var path = Path()
            
            for (index, value) in data.enumerated() {
                let x = CGFloat(index) * stepWidth
                let normalizedValue = CGFloat(min(value * 5, 1.0)) // Scale up for visibility
                let y = height / 2 - (normalizedValue * height / 2)
                let barHeight = normalizedValue * height
                
                path.addRect(CGRect(x: x, y: y, width: stepWidth * 0.8, height: barHeight))
            }
            
            context.fill(path, with: .color(.accentColor))
        }
    }
}

#Preview {
    @Previewable @State var sharedURL: URL? = nil
    DecoderView(sharedAudioURL: $sharedURL)
        .modelContainer(for: [Message.self], inMemory: true)
}
