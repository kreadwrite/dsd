//
//  LocalMusicLibrary.swift
//  Aura
//
//  Imported MP3 storage inside the app sandbox.
//

import Foundation
import Combine
import AVFoundation
import UIKit

@MainActor
final class LocalMusicLibrary: ObservableObject {
    struct PendingImport: Identifiable {
        let id = UUID()
        let fileURL: URL
        let suggestedTitle: String
        let suggestedArtist: String
        let duration: Int

        var durationText: String {
            let minutes = duration / 60
            let seconds = duration % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
    }

    static let shared = LocalMusicLibrary()

    @Published private(set) var tracks: [Track] = []

    private let fileManager = FileManager.default
    private let directoryName = "AuraLibrary"
    private let archiveName = "local-tracks.json"

    private init() {
        load()
    }

    var allTracks: [Track] {
        tracks
    }

    func prepareImport(from selectedURL: URL) async throws -> PendingImport {
        let didAccess = selectedURL.startAccessingSecurityScopedResource()
        defer {
            if didAccess {
                selectedURL.stopAccessingSecurityScopedResource()
            }
        }

        let sourceStem = selectedURL.deletingPathExtension().lastPathComponent
        let destinationURL = try copyIntoSandbox(sourceURL: selectedURL)
        let asset = AVURLAsset(url: destinationURL)
        let duration = Int((try await asset.load(.duration)).seconds.rounded())
        let parts = sourceStem.components(separatedBy: " - ")
        let suggestedArtist = parts.count > 1 ? parts.first ?? "" : ""
        let suggestedTitle = parts.count > 1 ? parts.dropFirst().joined(separator: " - ") : sourceStem

        return PendingImport(
            fileURL: destinationURL,
            suggestedTitle: suggestedTitle,
            suggestedArtist: suggestedArtist,
            duration: duration
        )
    }

    func importPreparedTrack(
        _ draft: PendingImport,
        title: String,
        artist: String,
        genre: Genre,
        notes: String?,
        artworkData: Data?
    ) async throws -> Track {
        let track = Track(
            id: "local_\(draft.fileURL.lastPathComponent)_\(UUID().uuidString)",
            source: "local",
            sourceID: draft.fileURL.lastPathComponent,
            title: title.isEmpty ? draft.suggestedTitle : title,
            artist: artist.isEmpty ? draft.suggestedArtist : artist,
            genre: genre.rawValue,
            duration: draft.duration,
            streamURL: draft.fileURL.path,
            imageURL: nil,
            isLocal: true,
            detailText: notes,
            externalURL: nil,
            lyrics: notes,
            isUserUploaded: true,
            artworkData: artworkData,
            initials: Self.initials(for: artist.isEmpty ? draft.suggestedArtist : artist, title: title.isEmpty ? draft.suggestedTitle : title),
            colorSeed: Self.colorSeed(for: title.isEmpty ? draft.suggestedTitle : title, artist: artist.isEmpty ? draft.suggestedArtist : artist)
        )

        tracks.insert(track, at: 0)
        try save()
        return track
    }

    func track(id: String) -> Track? {
        tracks.first { $0.id == id }
    }

    func updateTrack(
        id: String,
        title: String,
        artist: String,
        genre: Genre,
        notes: String?,
        artworkData: Data?
    ) throws {
        guard let index = tracks.firstIndex(where: { $0.id == id }) else { return }
        let old = tracks[index]
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanArtist = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        let newTitle = cleanTitle.isEmpty ? old.title : cleanTitle
        let newArtist = cleanArtist.isEmpty ? old.artist : cleanArtist
        tracks[index] = Track(
            id: old.id,
            source: old.source,
            sourceID: old.sourceID,
            title: newTitle,
            artist: newArtist,
            genre: genre.rawValue,
            duration: old.duration,
            streamURL: old.streamURL,
            imageURL: old.imageURL,
            isLocal: old.isLocal,
            detailText: notes,
            externalURL: old.externalURL,
            lyrics: notes,
            commentCount: old.commentCount,
            likeCount: old.likeCount,
            isUserUploaded: old.isUserUploaded,
            artworkData: artworkData ?? old.artworkData,
            initials: Self.initials(for: newArtist, title: newTitle),
            colorSeed: Self.colorSeed(for: newTitle, artist: newArtist)
        )
        try save()
    }

    func deleteTrack(id: String) throws {
        guard let index = tracks.firstIndex(where: { $0.id == id }) else { return }
        let track = tracks.remove(at: index)
        if track.isLocal {
            let url = URL(fileURLWithPath: track.streamURL)
            if fileManager.fileExists(atPath: url.path) {
                try? fileManager.removeItem(at: url)
            }
        }
        try save()
    }

    // MARK: - Persistence

    private struct StoredTrack: Codable {
        let id: String
        let title: String
        let artist: String
        let genre: String
        let duration: Int
        let streamURL: String
        let imageURL: String?
        let isLocal: Bool
        let detailText: String?
        let externalURL: String?
        let lyrics: String?
        let commentCount: Int
        let likeCount: Int
        let isUserUploaded: Bool
        let artworkData: Data?
        let initials: String
        let colorSeed: UInt

        init(
            id: String,
            title: String,
            artist: String,
            genre: String,
            duration: Int,
            streamURL: String,
            imageURL: String?,
            isLocal: Bool,
            detailText: String?,
            externalURL: String?,
            lyrics: String?,
            commentCount: Int,
            likeCount: Int,
            isUserUploaded: Bool,
            artworkData: Data?,
            initials: String,
            colorSeed: UInt
        ) {
            self.id = id
            self.title = title
            self.artist = artist
            self.genre = genre
            self.duration = duration
            self.streamURL = streamURL
            self.imageURL = imageURL
            self.isLocal = isLocal
            self.detailText = detailText
            self.externalURL = externalURL
            self.lyrics = lyrics
            self.commentCount = commentCount
            self.likeCount = likeCount
            self.isUserUploaded = isUserUploaded
            self.artworkData = artworkData
            self.initials = initials
            self.colorSeed = colorSeed
        }

        private enum CodingKeys: String, CodingKey {
            case id, title, artist, genre, duration, streamURL, imageURL, isLocal
            case detailText, externalURL, lyrics, commentCount, likeCount
            case isUserUploaded, artworkData, initials, colorSeed
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            id = try c.decode(String.self, forKey: .id)
            title = try c.decode(String.self, forKey: .title)
            artist = try c.decode(String.self, forKey: .artist)
            genre = try c.decode(String.self, forKey: .genre)
            duration = try c.decode(Int.self, forKey: .duration)
            streamURL = try c.decode(String.self, forKey: .streamURL)
            imageURL = try c.decodeIfPresent(String.self, forKey: .imageURL)
            isLocal = try c.decodeIfPresent(Bool.self, forKey: .isLocal) ?? true
            detailText = try c.decodeIfPresent(String.self, forKey: .detailText)
            externalURL = try c.decodeIfPresent(String.self, forKey: .externalURL)
            lyrics = try c.decodeIfPresent(String.self, forKey: .lyrics) ?? detailText
            commentCount = try c.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
            likeCount = try c.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
            isUserUploaded = try c.decodeIfPresent(Bool.self, forKey: .isUserUploaded) ?? isLocal
            artworkData = try c.decodeIfPresent(Data.self, forKey: .artworkData)
            initials = try c.decode(String.self, forKey: .initials)
            colorSeed = try c.decode(UInt.self, forKey: .colorSeed)
        }
    }

    private func load() {
        do {
            let url = try archiveURL()
            guard fileManager.fileExists(atPath: url.path) else { return }
            let data = try Data(contentsOf: url)
            let stored = try JSONDecoder().decode([StoredTrack].self, from: data)
            tracks = stored.map {
                Track(
                    id: $0.id,
                    title: $0.title,
                    artist: $0.artist,
                    genre: $0.genre,
                    duration: $0.duration,
                    streamURL: $0.streamURL,
                    imageURL: $0.imageURL,
                    isLocal: $0.isLocal,
                    detailText: $0.detailText,
                    externalURL: $0.externalURL,
                    lyrics: $0.lyrics,
                    commentCount: $0.commentCount,
                    likeCount: $0.likeCount,
                    isUserUploaded: $0.isUserUploaded,
                    artworkData: $0.artworkData,
                    initials: $0.initials,
                    colorSeed: $0.colorSeed
                )
            }
        } catch {
            tracks = []
        }
    }

    private func save() throws {
        let stored = tracks.map {
            StoredTrack(
                id: $0.id,
                title: $0.title,
                artist: $0.artist,
                genre: $0.genre,
                duration: $0.duration,
                streamURL: $0.streamURL,
                imageURL: $0.imageURL,
                isLocal: $0.isLocal,
                detailText: $0.detailText,
                externalURL: $0.externalURL,
                lyrics: $0.lyrics,
                commentCount: $0.commentCount,
                likeCount: $0.likeCount,
                isUserUploaded: $0.isUserUploaded,
                artworkData: $0.artworkData,
                initials: $0.initials,
                colorSeed: $0.colorSeed
            )
        }
        let data = try JSONEncoder().encode(stored)
        try data.write(to: archiveURL(), options: [.atomic])
    }

    private func archiveURL() throws -> URL {
        let dir = try applicationSupportDirectory()
        let folder = dir.appendingPathComponent(directoryName, isDirectory: true)
        if !fileManager.fileExists(atPath: folder.path) {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder.appendingPathComponent(archiveName)
    }

    private func applicationSupportDirectory() throws -> URL {
        try fileManager.url(for: .applicationSupportDirectory,
                            in: .userDomainMask,
                            appropriateFor: nil,
                            create: true)
    }

    private func copyIntoSandbox(sourceURL: URL) throws -> URL {
        let dir = try applicationSupportDirectory()
        let folder = dir.appendingPathComponent(directoryName, isDirectory: true)
        if !fileManager.fileExists(atPath: folder.path) {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }

        let uniqueName = "\(UUID().uuidString)-\(sourceURL.lastPathComponent)"
        let destinationURL = folder.appendingPathComponent(uniqueName)
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        return destinationURL
    }

    private static func initials(for artist: String, title: String) -> String {
        let source = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = source.isEmpty ? title : source
        let letters = value.split(separator: " ").prefix(2).map { $0.prefix(1) }
        let joined = letters.joined().uppercased()
        return joined.isEmpty ? "A" : String(joined.prefix(2))
    }

    private static func colorSeed(for title: String, artist: String) -> UInt {
        let raw = (title + artist).unicodeScalars.reduce(into: UInt(0)) { $0 = $0 &+ UInt($1.value) }
        return raw == 0 ? 0x1DB954 : raw
    }
}
