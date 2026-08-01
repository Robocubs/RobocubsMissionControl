//
//  MediaTranscoder.swift
//  PitMissionController
//
//  Converts a picked video into something the Pi's Chromium kiosk can
//  actually play before it gets uploaded.
//
//  Two things happen here, and BOTH matter even for "Original":
//
//  1. Preset selection. 1080p/720p re-encode to H.264/AAC (and tone-map
//     HDR down to SDR along the way), which is what the Pi 5 can decode —
//     it has no H.264 hardware decode block at all, but that resolution is
//     comfortable in software. Original uses AVAssetExportPresetPassthrough,
//     deliberately NOT one of the HEVC presets, so it keeps the source
//     codec as-is rather than re-encoding into HEVC.
//
//  2. Fast-start remux. iPhone captures place the `moov` atom at the END
//     of the file. A browser can't start playback (or seek at all) until
//     it has the whole file over the network, which for a multi-GB clip
//     over pit wifi is a multi-minute stall and a dead scrubber. Passthrough
//     with shouldOptimizeForNetworkUse=true does a fast remux (no re-encode)
//     that relocates moov to the front — so even "Original" always goes
//     through this export session, never a raw file copy.
//

import AVFoundation
import Foundation

enum TranscodeError: Error {
    case incompatiblePreset
    case exportFailed(String)
    case cancelled
}

struct TranscodeResult {
    let outputURL: URL
    let duration: Double
    let width: Int
    let height: Int
}

enum MediaTranscoder {
    private static func presetName(for quality: VideoQuality) -> String {
        switch quality {
        case .original: return AVAssetExportPresetPassthrough
        case .p1080: return AVAssetExportPreset1920x1080
        case .p720: return AVAssetExportPreset1280x720
        }
    }

    /// Transcodes `sourceURL` per `quality`, reporting fractional progress
    /// via `onProgress` (main-thread callback). The caller owns cleanup of
    /// both `sourceURL` and the returned output URL.
    static func transcode(
        sourceURL: URL,
        quality: VideoQuality,
        onProgress: @escaping (Double) -> Void
    ) async throws -> TranscodeResult {
        let asset = AVURLAsset(url: sourceURL)

        // Load duration + tracks up front via the async key-value loading API.
        let duration = try await asset.load(.duration)
        let tracks = try await asset.loadTracks(withMediaType: .video)
        var width = 0
        var height = 0
        if let track = tracks.first {
            let naturalSize = try await track.load(.naturalSize)
            let transform = try await track.load(.preferredTransform)
            let transformedSize = naturalSize.applying(transform)
            width = Int(abs(transformedSize.width))
            height = Int(abs(transformedSize.height))
        }

        let preset = presetName(for: quality)

        // exportPresets(compatibleWith:) — the bulk "list all compatible
        // presets" call — was deprecated in iOS/macOS 16/13 in favor of
        // checking one preset at a time via this async method, which we
        // need anyway below for the output-file-type check. outputFileType:
        // nil here means "just check the preset itself, ignore container."
        guard await AVAssetExportSession.compatibility(ofExportPreset: preset, with: asset, outputFileType: nil) else {
            throw TranscodeError.incompatiblePreset
        }

        guard let session = AVAssetExportSession(asset: asset, presetName: preset) else {
            throw TranscodeError.exportFailed("Could not create export session")
        }

        // Relocates moov to the front of the file even on a passthrough
        // (no re-encode) export — this is what actually fixes the
        // start-of-playback / seeking problem described above.
        session.shouldOptimizeForNetworkUse = true

        var outputFileType: AVFileType = .mp4
        if !(await AVAssetExportSession.compatibility(ofExportPreset: preset, with: asset, outputFileType: .mp4)) {
            // Some passthrough sources (e.g. certain HEVC/Dolby Vision
            // captures) aren't representable as .mp4 without re-encoding.
            // Fall back to .mov rather than fail outright; the caller
            // surfaces this via the returned file extension so the upload
            // step and the UI can flag it as "may not play on cart."
            outputFileType = .mov
        }

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(outputFileType == .mp4 ? "mp4" : "mov")

        let progressTask = Task {
            for await state in session.states(updateInterval: 0.25) {
                if case .exporting(let progress) = state {
                    let fraction = progress.fractionCompleted
                    await MainActor.run { onProgress(fraction) }
                }
            }
        }

        do {
            try await session.export(to: outputURL, as: outputFileType)
        } catch is CancellationError {
            progressTask.cancel()
            throw TranscodeError.cancelled
        } catch {
            progressTask.cancel()
            throw TranscodeError.exportFailed(error.localizedDescription)
        }
        progressTask.cancel()

        return TranscodeResult(
            outputURL: outputURL,
            duration: duration.seconds,
            width: width,
            height: height
        )
    }
}
