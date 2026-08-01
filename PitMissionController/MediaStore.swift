//
//  MediaStore.swift
//  PitMissionController
//
//  Local-video state shared across the picker, transcoder, uploader, and
//  the library/transport UI. Follows the same pattern as `sharedStates`
//  and `PopoverCache.shared` in SharedStates.swift: a single ObservableObject
//  instance published globally rather than threaded through every view.
//

import Combine
import Foundation

/// One uploaded video as known to the Pi's media library.
public struct MediaItem: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let quality: String
    public let duration: Double
    public let size: Int
    public let width: Int
    public let height: Int
    public let uploadedAt: Double
}

/// A live playback status report from a cart's <video> element.
public struct PlaybackStatus: Codable, Equatable {
    public let id: String
    public let position: Double
    public let duration: Double
    public let paused: Bool
    public let muted: Bool
    public let loop: Bool
    public let ended: Bool
    public let ready: Bool
}

/// A transport command sent to a cart. Flat optionals (rather than an enum)
/// so the Pi side can read `data.get("seconds")` / `data.get("flag")`
/// without any custom decoding.
public struct PlaybackCommand: Codable {
    public let action: String
    public var seconds: Double?
    public var flag: Bool?

    public static func play() -> PlaybackCommand { .init(action: "play") }
    public static func pause() -> PlaybackCommand { .init(action: "pause") }
    public static func restart() -> PlaybackCommand { .init(action: "restart") }
    public static func seek(_ seconds: Double) -> PlaybackCommand { .init(action: "seek", seconds: seconds) }
    public static func mute(_ flag: Bool) -> PlaybackCommand { .init(action: "mute", flag: flag) }
    public static func loop(_ flag: Bool) -> PlaybackCommand { .init(action: "loop", flag: flag) }
}

/// Video quality options offered in the upload sheet. Not HEVC: Chromium on
/// the Pi cannot use the Pi 5's HEVC decode block, and the non-HEVC presets
/// also tone-map HDR/Dolby Vision captures down to SDR automatically.
public enum VideoQuality: String, CaseIterable, Identifiable {
    case original = "Original"
    case p1080 = "1080p"
    case p720 = "720p"

    public var id: String { rawValue }

    /// User-facing note surfaced next to the picker — the Pi 5 has no H.264
    /// hardware decode at all, and Chromium likely can't reach the HEVC
    /// block either, so an untouched 4K/HEVC capture is a real gamble.
    public var caveat: String? {
        switch self {
        case .original: return "May not play — Pi decode is not guaranteed at full 4K."
        case .p1080, .p720: return nil
        }
    }
}

@MainActor
public final class MediaStore: ObservableObject {
    @Published public var library: [MediaItem] = []
    @Published public var selectedL: String?
    @Published public var selectedR: String?
    @Published public var statusL: PlaybackStatus?
    @Published public var statusR: PlaybackStatus?

    @Published public var uploadProgress: Double?
    @Published public var uploadPhase: String?
    @Published public var uploadError: String?

    public func item(for id: String?) -> MediaItem? {
        guard let id else { return nil }
        return library.first { $0.id == id }
    }
}

@MainActor
public let mediaStore = MediaStore()
