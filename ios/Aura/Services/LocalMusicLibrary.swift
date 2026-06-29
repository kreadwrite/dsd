//
//  LocalMusicLibrary.swift
//  Aura
//

import Foundation
import AVFoundation
import UIKit

@MainActor
final class LocalMusicLibrary: ObservableObject {
    static let shared = LocalMusicLibrary()

    @Published private(set) var tracks: [Track] = []

    private struct StoredTrack: Codable {
        let id: String
        let title: String
        let artist: String
        let genre: String
        let duration: Int
        let streamURL: String
        let initials: String
        let colorSeed: UInt
        let detailText: String?
        let artworkBase64: String?
    }

    private let folderURL: URL
    private let storeURL: URL
    private let fm = FileManager.default

    private init() {
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.temporaryDirectory
        folderURL = base.appendingPathComponent("AuraLibrary", isDirectory: true)
        storeURL = folderURL.appendingPathComponent("local-tracks.json")
        try? fm.createDirectory(at: folderURL, withIntermediateDirectories: true)
        load()
    }

    func importedTracks() -> [Track] {
        tracks
    }

    func searchTracks(matching query: String) -> [Track] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return tracks }
        return tracks.filter {
            $0.title.localizedCaseInsensitiveContains(q) ||
            $0.artist.localizedCaseInsensitiveContains(q) ||
            $0.genre.localizedCaseInsensitiveContains(q) ||
            ($0.detailText?.localizedCaseInsensitiveContains(q) == true)
        }
    }

    func importTrack(
        from sourceURL: URL,
        title: String,
        artist: String,
        genre: Genre,
        notes: String? = nil,
        artworkData: Data? = nil
    ) async throws -> Track {
        let ext = sourceURL.pathExtension.isEmpty ? "mp3" : sourceURL.pathExtension
        let localName = UUID().uuidString.appending(".\(ext)")
        let destinationURL = folderURL.appendingPathComponent(localName)

        if sourceURL.startAccessingSecurityScopedResource() {
            defer { sourceURL.stopAccessingSecurityScopedResource() }
        }

        if fm.fileExists(atPath: destinationURL.path) {
            try? fm.removeItem(at: destinationURL)
        }
        try fm.copyItem(at: sourceURL, to: destinationURL)

        let asset = AVURLAsset(url: destinationURL)
        let durationTime = try await asset.load(.duration)
        let duration = max(0, Int(durationTime.seconds.rounded()))
        let initials = Self.makeInitials(from: artist, title: title)
        let colorSeed = Self.colorSeed(from: title + artist)

        let track = Track(
            id: "local_\(UUID().uuidString)",
            title: title,
            artist: artist,
            genre: genre.rawValue,
            duration: duration,
            streamURL: destinationURL.path,
            imageURL: nil,
            initials: initials,
            colorSeed: colorSeed,
            isLocal: true,
            detailText: notes?.trimmingCharacters(in: .whitespacesAndNewlines),
            artworkData: artworkData
        )

        tracks.insert(track, at: 0)
        save()
        return track
    }

    private func load() {
        guard let data = try? Data(contentsOf: storeURL) else { return }
        do {
            let stored = try JSONDecoder().decode([StoredTrack].self, from: data)
            tracks = stored.compactMap { record in
                Track(
                    id: record.id,
                    title: record.title,
                    artist: record.artist,
                    genre: record.genre,
                    duration: record.duration,
                    streamURL: record.streamURL,
                    imageURL: nil,
                    initials: record.initials,
                    colorSeed: record.colorSeed,
                    isLocal: true,
                    detailText: record.detailText,
                    artworkData: record.artworkBase64.flatMap(Data.init(base64Encoded:))
                )
            }
        } catch {
            tracks = []
        }
    }

    private func save() {
        let stored = tracks.map {
            StoredTrack(
                id: $0.id,
                title: $0.title,
                artist: $0.artist,
                genre: $0.genre,
                duration: $0.duration,
                streamURL: $0.streamURL,
                initials: $0.initials,
                colorSeed: $0.colorSeed,
                detailText: $0.detailText,
                artworkBase64: $0.artworkData?.base64EncodedString()
            )
        }
        guard let data = try? JSONEncoder().encode(stored) else { return }
        try? data.write(to: storeURL, options: .atomic)
    }

    private static func makeInitials(from artist: String, title: String) -> String {
        let seed = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        if seed.count >= 2 {
            return String(seed.prefix(2)).uppercased()
        }
        return String(title.prefix(2)).uppercased()
    }

    private static func colorSeed(from value: String) -> UInt {
        var hash: UInt = 0x1DB954
        for scalar in value.unicodeScalars {
            hash = hash &* 31 &+ UInt(scalar.value)
        }
        let green = 0x1DB954 as UInt
        let bright = 0x1ED760 as UInt
        return hash.isMultiple(of: 2) ? green : bright
    }
}
