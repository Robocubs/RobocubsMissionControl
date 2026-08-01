//
//  MediaLibraryPopover.swift
//  PitMissionController
//
//  The "Local Video" long-press sheet for one cart side: browse/select from
//  what's already uploaded to the Pi, add a new video (pick -> choose
//  quality -> transcode -> upload), and — once something is selected —
//  the transport controls to play it back.
//
//  Presented from Control.swift exactly like TextFieldPopover, just larger
//  (.large detent instead of a fixed 150pt height) since it hosts a list.
//

import SwiftUI

struct MediaLibraryPopover: View {
    let side: String // "L" or "R"
    @Binding var isPresented: Bool

    @ObservedObject private var store = mediaStore

    @State private var showingPicker = false
    @State private var pendingPickedURL: URL?
    @State private var selectedQuality: VideoQuality = .p1080
    @State private var isProcessing = false
    @State private var processingPhase: String?
    @State private var processingProgress: Double = 0
    @State private var errorMessage: String?

    private var selectedId: String? {
        side == "L" ? store.selectedL : store.selectedR
    }

    private var status: PlaybackStatus? {
        side == "L" ? store.statusL : store.statusR
    }

    private var sideName: String {
        side == "L" ? "Left" : "Right"
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if let selectedId, let item = store.item(for: selectedId) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(item.name)
                            .font(.headline)
                            .lineLimit(1)
                        VideoTransportControls(side: side, status: status)
                    }
                    .padding()
                    Divider()
                }

                if let pendingPickedURL {
                    pendingUploadSection(for: pendingPickedURL)
                    Divider()
                }

                List {
                    Section("Library — expires 48h after upload") {
                        if store.library.isEmpty {
                            Text("No videos uploaded yet")
                                .foregroundStyle(.secondary)
                        }
                        ForEach(store.library) { item in
                            libraryRow(item)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    socket.sendMessage(type: "localVideo\(side)Update", data: item.id)
                                }
                        }
                        .onDelete(perform: deleteItems)
                    }
                }
                .listStyle(.plain)

                if pendingPickedURL == nil {
                    Button {
                        showingPicker = true
                    } label: {
                        Label("Add Video", systemImage: "plus.circle.fill")
                            .font(.title3)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    .disabled(isProcessing)
                }
            }
            .navigationTitle("Local Video — \(sideName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", systemImage: "checkmark") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackgroundInteraction(.enabled)
        .onAppear {
            socket.sendMessage(type: "localVideoLibraryRequest", data: "")
        }
        .sheet(isPresented: $showingPicker) {
            MediaPicker(
                onPick: { url in
                    // MediaPicker's coordinator already calls
                    // picker.dismiss(animated:) itself — PHPickerViewController
                    // requires that. showingPicker still needs to be set to
                    // false here too, or SwiftUI's own bookkeeping for this
                    // .sheet binding falls out of sync with what's actually
                    // on screen, and a second "Add Video" tap can silently
                    // fail to re-present the picker.
                    showingPicker = false
                    pendingPickedURL = url
                },
                onCancel: {
                    showingPicker = false
                }
            )
        }
        .alert("Upload Failed", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func pendingUploadSection(for url: URL) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if isProcessing {
                VStack(alignment: .leading, spacing: 6) {
                    Text(processingPhase ?? "Preparing…")
                        .font(.subheadline)
                    ProgressView(value: processingProgress)
                }
            } else {
                Text("Picked: \(url.lastPathComponent)")
                    .font(.subheadline)
                    .lineLimit(1)

                Picker("Quality", selection: $selectedQuality) {
                    ForEach(VideoQuality.allCases) { quality in
                        Text(quality.rawValue).tag(quality)
                    }
                }
                .pickerStyle(.segmented)

                if let caveat = selectedQuality.caveat {
                    Text(caveat)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                HStack {
                    Button("Cancel", role: .cancel) {
                        try? FileManager.default.removeItem(at: url)
                        pendingPickedURL = nil
                    }
                    Spacer()
                    Button("Upload") {
                        beginUpload(from: url)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
    }

    @ViewBuilder
    private func libraryRow(_ item: MediaItem) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .lineLimit(1)
                Text("\(item.quality) · \(formattedDuration(item.duration)) · \(formattedSize(item.size))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if item.id == selectedId {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
            }
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = store.library[index]
            socket.sendMessage(type: "localVideoDelete", data: item.id)
        }
    }

    private func beginUpload(from pickedURL: URL) {
        isProcessing = true
        processingPhase = "Transcoding"
        processingProgress = 0
        let quality = selectedQuality
        let name = pickedURL.deletingPathExtension().lastPathComponent

        Task {
            do {
                let transcoded = try await MediaTranscoder.transcode(
                    sourceURL: pickedURL,
                    quality: quality
                ) { progress in
                    processingProgress = progress
                }

                processingPhase = "Uploading"
                processingProgress = 0

                let uploader = MediaUploader()
                _ = try await uploader.upload(
                    fileURL: transcoded.outputURL,
                    name: name,
                    quality: quality,
                    duration: transcoded.duration,
                    width: transcoded.width,
                    height: transcoded.height
                ) { progress in
                    processingProgress = progress
                }

                try? FileManager.default.removeItem(at: pickedURL)
                try? FileManager.default.removeItem(at: transcoded.outputURL)
                isProcessing = false
                pendingPickedURL = nil
            } catch {
                try? FileManager.default.removeItem(at: pickedURL)
                isProcessing = false
                errorMessage = "\(error)"
                // Leave pendingPickedURL set to nil rather than retry the
                // same (now-deleted) temp file — the user re-picks.
                pendingPickedURL = nil
            }
        }
    }

    private func formattedDuration(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private func formattedSize(_ bytes: Int) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }
}
