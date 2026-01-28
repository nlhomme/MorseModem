//
//  MessageDetailView.swift
//  MorseModem
//

import SwiftUI

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
                            ClipboardHelper.copy(message.text)
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
                            ClipboardHelper.copy(message.morseCode)
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
}

#Preview {
    NavigationStack {
        MessageDetailView(message: Message(
            text: "Hello World",
            morseCode: ".... . .-.. .-.. ---  .-- --- .-. .-.. -..",
            isEncoded: true
        ))
    }
}
