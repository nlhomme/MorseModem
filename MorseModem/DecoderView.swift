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
                        if viewModel?.morseDecoder.isRecording == true {
                            // Recording indicator
                            HStack {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 12, height: 12)
                                    .scaleEffect(1.2)
                                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: viewModel?.morseDecoder.isRecording)
                                
                                Text("Recording...")
                                    .font(.headline)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            // Waveform visualization
                            if let waveform = viewModel?.morseDecoder.waveformData, !waveform.isEmpty {
                                WaveformView(data: waveform)
                                    .frame(height: 100)
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        
                        // Record Button
                        Button {
                            Task {
                                if viewModel?.morseDecoder.isRecording == true {
                                    viewModel?.stopRecording()
                                } else {
                                    await viewModel?.startRecording()
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: viewModel?.morseDecoder.isRecording == true ? "stop.circle.fill" : "mic.circle.fill")
                                    .font(.title2)
                                Text(viewModel?.morseDecoder.isRecording == true ? "Stop Recording" : "Start Recording")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(viewModel?.morseDecoder.isRecording == true ? Color.red : Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .accessibilityLabel(viewModel?.morseDecoder.isRecording == true ? "Stop recording" : "Start recording")
                        
                        // Import Button
                        Button {
                            showFilePicker = true
                        } label: {
                            HStack {
                                if viewModel?.isImporting == true {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "doc.badge.plus")
                                    Text("Import Audio File")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(viewModel?.isImporting == true || viewModel?.morseDecoder.isRecording == true)
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
