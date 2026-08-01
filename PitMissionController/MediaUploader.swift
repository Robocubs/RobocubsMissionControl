//
//  MediaUploader.swift
//  PitMissionController
//
//  Streams a transcoded video to the Pi's /api/media/upload endpoint.
//

import Foundation

enum UploadError: Error {
    case invalidResponse
    case serverError(Int, String)
}

struct UploadResult: Codable {
    let id: String
    let url: String
}

@MainActor
final class MediaUploader: NSObject, URLSessionTaskDelegate {
    private var progressHandler: ((Double) -> Void)?

    /// Uploads `fileURL` to the Pi and returns the new media id + URL.
    /// `fileURL` is streamed from disk (not loaded into memory), so this is
    /// safe to call with a multi-gigabyte file.
    func upload(
        fileURL: URL,
        name: String,
        quality: VideoQuality,
        duration: Double,
        width: Int,
        height: Int,
        onProgress: @escaping (Double) -> Void
    ) async throws -> UploadResult {
        progressHandler = onProgress

        var components = URLComponents(
            url: mediaBaseURL.appendingPathComponent("/api/media/upload"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "name", value: name),
            URLQueryItem(name: "quality", value: quality.rawValue),
            URLQueryItem(name: "duration", value: String(duration)),
            URLQueryItem(name: "width", value: String(width)),
            URLQueryItem(name: "height", value: String(height)),
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("video/mp4", forHTTPHeaderField: "Content-Type")

        let config = URLSessionConfiguration.default
        // Inactivity timeout, not a total-duration cap — a slow pit wifi
        // upload that's still making progress shouldn't be killed.
        config.timeoutIntervalForRequest = 300
        config.timeoutIntervalForResource = 3600
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }

        // fromFile: is essential here — it streams from disk and lets
        // URLSession set Content-Length from the file size, rather than
        // requiring the whole upload body to be materialized in memory.
        let (data, response) = try await session.upload(for: request, fromFile: fileURL)

        guard let http = response as? HTTPURLResponse else {
            throw UploadError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw UploadError.serverError(http.statusCode, body)
        }

        return try JSONDecoder().decode(UploadResult.self, from: data)
    }

    // nonisolated because SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor makes
    // this type MainActor-isolated by default, but URLSessionTaskDelegate
    // callbacks arrive on an arbitrary background queue and must not be
    // implicitly hopped to the main actor by the compiler for us.
    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        guard totalBytesExpectedToSend > 0 else { return }
        let fraction = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
        Task { @MainActor in
            self.progressHandler?(fraction)
        }
    }
}
