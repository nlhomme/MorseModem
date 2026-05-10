//
//  HistoryView.swift
//  MorseModem
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
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(message.isEncoded ? "Encoded" : "Decoded") message: \(message.text), \(message.timestamp.formatted(date: .abbreviated, time: .shortened))")
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

        do {
            try modelContext.save()
        } catch {
            print("Error clearing history: \(error)")
        }
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: Message.self, inMemory: true)
}
