//
//  HistoryView.swift
//  MorseModem
//
//  Created by Nicolas Lhomme on 26/01/2026.
//

import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Message.timestamp, order: .reverse) private var messages: [Message]
    
    @State private var searchText = ""
    @State private var showClearAllConfirmation = false
    
    private var filteredMessages: [Message] {
        if searchText.isEmpty {
            return messages
        }
        
        return messages.filter { message in
            message.text.localizedCaseInsensitiveContains(searchText) ||
            message.morseCode.contains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredMessages) { message in
                    NavigationLink {
                        MessageDetailView(message: message)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Label(
                                    message.isEncoded ? "Encoded" : "Decoded",
                                    systemImage: message.isEncoded ? "square.and.arrow.up" : "square.and.arrow.down"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Text(message.timestamp, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Text(message.text)
                                .lineLimit(2)
                            
                            Text(message.morseCode)
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: deleteMessages)
            }
            .navigationTitle("History")
            .searchable(text: $searchText, prompt: "Search messages")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button(role: .destructive) {
                        showClearAllConfirmation = true
                    } label: {
                        Label("Clear All", systemImage: "trash")
                    }
                    .disabled(messages.isEmpty)
                }
            }
            .confirmationDialog(
                "Clear All History",
                isPresented: $showClearAllConfirmation,
                titleVisibility: .visible
            ) {
                Button("Clear All", role: .destructive) {
                    clearAllMessages()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete all \(messages.count) messages? This action cannot be undone.")
            }
            .overlay {
                if filteredMessages.isEmpty {
                    if searchText.isEmpty {
                        ContentUnavailableView(
                            "No History",
                            systemImage: "clock",
                            description: Text("Your encoded and decoded messages will appear here")
                        )
                    } else {
                        ContentUnavailableView.search(text: searchText)
                    }
                }
            }
        }
    }
    
    private func deleteMessages(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(filteredMessages[index])
        }
    }
    
    private func clearAllMessages() {
        for message in messages {
            modelContext.delete(message)
        }
        
        // Save the context to persist the deletion
        do {
            try modelContext.save()
        } catch {
            print("Error clearing history: \(error)")
        }
    }
}

struct MessageDetailView: View {
    let message: Message
    @State private var showCopiedAlert = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(
                            message.isEncoded ? "Encoded Message" : "Decoded Message",
                            systemImage: message.isEncoded ? "square.and.arrow.up" : "square.and.arrow.down"
                        )
                        .font(.headline)
                        
                        Spacer()
                    }
                    
                    Text(message.timestamp, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text(message.timestamp, style: .time)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                // Text
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Text")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button {
                            copyToClipboard(message.text)
                            showCopiedAlert = true
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    Text(message.text)
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
                
                // Morse Code
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Morse Code")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button {
                            copyToClipboard(message.morseCode)
                            showCopiedAlert = true
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        Text(message.morseCode)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                    }
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
        .navigationTitle("Message Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Copied", isPresented: $showCopiedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Copied to clipboard")
        }
    }
    
    private func copyToClipboard(_ text: String) {
        #if os(iOS)
        UIPasteboard.general.string = text
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
    }
}

#Preview("History") {
    HistoryView()
        .modelContainer(for: Message.self, inMemory: true)
}

#Preview("Message Detail") {
    NavigationStack {
        MessageDetailView(message: Message(
            text: "Hello World",
            morseCode: ".... . .-.. .-.. ---  .-- --- .-. .-.. -..",
            isEncoded: true
        ))
    }
}
