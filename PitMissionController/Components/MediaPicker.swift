//
//  MediaPicker.swift
//  PitMissionController
//
//  Wraps PHPickerViewController to pick a single video from Photos.
//
//  Deliberately constructed WITHOUT `photoLibrary:` in the configuration,
//  which keeps the picker running out-of-process (the standard iOS 14+
//  picker UI, not our app). That means PitMissionController never touches
//  the photo library directly and needs NO NSPhotoLibraryUsageDescription
//  at all — the tradeoff is that we get a copy of the file rather than
//  in-place access, which is what AirDropped 4K clips make unavoidable
//  here anyway (the export session downstream needs a real file to read).
//

import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct MediaPicker: UIViewControllerRepresentable {
    var onPick: (URL) -> Void
    var onCancel: (() -> Void)? = nil

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1
        config.preferredAssetRepresentationMode = .current
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: MediaPicker

        init(_ parent: MediaPicker) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)

            guard let provider = results.first?.itemProvider,
                  provider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) else {
                parent.onCancel?()
                return
            }

            // The completion handler here is 3 arguments, not 2 — the
            // middle Bool ("isInPlace") isn't something we need: we copy
            // synchronously below regardless of its value, since the URL is
            // deleted the instant this closure returns either way.
            _ = provider.loadFileRepresentation(for: .movie) { [parent] url, _, error in
                guard let url, error == nil else {
                    DispatchQueue.main.async { parent.onCancel?() }
                    return
                }

                // CRITICAL: the URL handed to this closure is deleted the
                // instant the closure returns. The copy into our own temp
                // directory must happen synchronously, right here — not
                // dispatched, not deferred. This closure already runs off
                // the main thread, so the copy (which can be several
                // seconds for a 4K clip) doesn't block the UI.
                let destination = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension(url.pathExtension.isEmpty ? "mov" : url.pathExtension)

                do {
                    try FileManager.default.copyItem(at: url, to: destination)
                } catch {
                    print("[MediaPicker] Failed to copy picked video: \(error)")
                    DispatchQueue.main.async { parent.onCancel?() }
                    return
                }

                DispatchQueue.main.async {
                    parent.onPick(destination)
                }
            }
        }
    }
}
