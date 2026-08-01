//
//  VideoTransportControls.swift
//  PitMissionController
//
//  Play/pause/restart/mute/loop plus a scrubber, bound to whichever cart's
//  PlaybackStatus is currently known. Status arrives from the cart at
//  roughly 2Hz over the websocket (see LocalVideo.svelte's report()), which
//  is fast enough to fight a finger on the slider if not guarded against —
//  hence isScrubbing and the brief post-release ignore window below.
//

import SwiftUI

struct VideoTransportControls: View {
    let side: String // "L" or "R"
    let status: PlaybackStatus?

    @State private var isScrubbing = false
    @State private var scrubValue: Double = 0
    @State private var ignoreInboundUntil: Date = .distantPast

    private var duration: Double {
        max(status?.duration ?? 0, 0.01)
    }

    private var displayPosition: Double {
        if isScrubbing { return scrubValue }
        if Date() < ignoreInboundUntil { return scrubValue }
        return min(status?.position ?? 0, duration)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 32) {
                Button {
                    send(.restart())
                } label: {
                    Image(systemName: "gobackward")
                }

                Button {
                    send((status?.paused ?? true) ? .play() : .pause())
                } label: {
                    Image(systemName: (status?.paused ?? true) ? "play.fill" : "pause.fill")
                }

                Button {
                    send(.mute(!(status?.muted ?? true)))
                } label: {
                    Image(systemName: (status?.muted ?? true) ? "speaker.slash.fill" : "speaker.wave.2.fill")
                }

                Button {
                    send(.loop(!(status?.loop ?? false)))
                } label: {
                    Image(systemName: "repeat")
                        .foregroundStyle((status?.loop ?? false) ? Color.accentColor : Color.primary)
                }
            }
            .font(.title2)
            .disabled(status == nil)

            Slider(
                value: Binding(
                    get: { displayPosition },
                    set: { scrubValue = $0 }
                ),
                in: 0...duration,
                onEditingChanged: { editing in
                    if editing {
                        scrubValue = status?.position ?? 0
                        isScrubbing = true
                    } else {
                        send(.seek(scrubValue))
                        isScrubbing = false
                        // Absorb any status report that was already in
                        // flight before the seek landed, so the thumb
                        // doesn't snap back to the pre-seek position.
                        ignoreInboundUntil = Date().addingTimeInterval(0.7)
                    }
                }
            )
            .disabled(status == nil)

            Text("\(formatted(displayPosition)) / \(formatted(duration))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }

    private func send(_ command: PlaybackCommand) {
        socket.sendMessage(type: "localVideo\(side)Command", data: command)
    }

    private func formatted(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
