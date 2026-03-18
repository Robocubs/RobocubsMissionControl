//
//  TextPopover.swift
//  RobocubsMissionControl
//
//  Created by Quincy D on 10/13/25.
//

import SwiftUI

private enum Field: Hashable {
    case textInput
}

struct TextFieldPopover: View {
    let title: String
    let messageType: String

    @Binding var isPresented: Bool

    @State private var text: String
    @ObservedObject private var cache = PopoverCache.shared

    @FocusState private var focusedField: Field?

    init(title: String, messageType: String, isPresented: Binding<Bool>) {
        self.title = title
        self.messageType = messageType
        self._isPresented = isPresented
        // Pre-populate with the full display URL built from the cached ID
        let cachedID = PopoverCache.shared.get(messageType)
        self._text = State(initialValue: Self.displayString(for: messageType, id: cachedID))
    }

    /// Reconstructs the full URL for display given a stored ID, or returns the ID as-is if not applicable.
    private static func displayString(for messageType: String, id: String) -> String {
        guard !id.isEmpty else { return "" }
        switch messageType {
        case "youtubeLUpdate", "youtubeRUpdate":
            return "https://www.youtube.com/watch?v=\(id)"
        case "twitchLUpdate", "twitchRUpdate":
            return "https://www.twitch.tv/\(id)"
        default:
            return id
        }
    }

    /// Extracts the sendable ID from whatever the user typed.
    private func extractID(from input: String) -> String {
        guard let url = URL(string: input) else { return input }
        switch messageType {
        case "youtubeLUpdate", "youtubeRUpdate":
            if let videoID = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name == "v" })?.value {
                return videoID
            }
            // Handles /live/ID and youtu.be/ID
            return url.lastPathComponent
        case "twitchLUpdate", "twitchRUpdate":
            return url.lastPathComponent
        default:
            return input
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                TextField(title, text: $text)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(Color(.systemGray5))
                    .focused($focusedField, equals: .textInput)
            }
            .cornerRadius(30)
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(.title3.bold())
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", systemImage: "checkmark") {
                        let id = extractID(from: text)
                        cache.set(id, for: messageType)
                        // Show the full URL in the field after submit
                        text = Self.displayString(for: messageType, id: id)
                        socket.sendMessage(type: messageType, data: id)
                        isPresented = false
                    }
                    .disabled(text.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 150)
        .presentationDetents([.height(150)])
        .presentationSizing(.fitted)
//        .presentationBackground(.clear)
        .presentationBackgroundInteraction(.enabled)
        .onAppear {
            focusedField = .textInput
        }
    }
}

#Preview {
    VStack {}
        .sheet(isPresented: .constant(true)) {
            TextFieldPopover(title: "Twitch Channel", messageType: "twitchLUpdate", isPresented: .constant(true))
        }
}
