//
//  MusicModels.swift
//  Aura
//

import Foundation
import SwiftUI
import UIKit

/// A playable track. Cover is either a remote image URL (Jamendo) or a
/// generated solid-colour placeholder built from the artist initials.
nonisolated struct Track: Identifiable, Hashable, Codable {
    let id: String
    let source: String
    let sourceID: String?
    let title: String
    let artist: String
    let genre: String
    /// Duration in seconds.
    let duration: Int
    /// Streamable audio URL (Jamendo or royalty-free sample).
    let streamURL: String
    /// Optional remote cover image URL.
    let imageURL: String?
    /// Set when the track is imported locally from Files.
    let isLocal: Bool
    /// Optional notes/description provided by the user.
    let detailText: String?
    let externalURL: String?
    let lyrics: String?
    let commentCount: Int
    let likeCount: Int
    let isUserUploaded: Bool
    /// Optional imported artwork stored in the sandbox.
    let artworkData: Data?
    /// Two-letter initials used for the placeholder cover.
    let initials: String
    /// Hex colour seed for the placeholder cover gradient.
    let colorSeed: UInt

    init(
        id: String,
        source: String = "catalog",
        sourceID: String? = nil,
        title: String,
        artist: String,
        genre: String,
        duration: Int,
        streamURL: String,
        imageURL: String?,
        isLocal: Bool,
        detailText: String?,
        externalURL: String? = nil,
        lyrics: String? = nil,
        commentCount: Int = 0,
        likeCount: Int = 0,
        isUserUploaded: Bool = false,
        artworkData: Data?,
        initials: String,
        colorSeed: UInt
    ) {
        self.id = id
        self.source = source
        self.sourceID = sourceID
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
        case id, source, sourceID, title, artist, genre, duration, streamURL, imageURL
        case isLocal, detailText, externalURL, lyrics, commentCount, likeCount
        case isUserUploaded, artworkData, initials, colorSeed
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        source = try c.decodeIfPresent(String.self, forKey: .source) ?? "catalog"
        sourceID = try c.decodeIfPresent(String.self, forKey: .sourceID)
        title = try c.decode(String.self, forKey: .title)
        artist = try c.decode(String.self, forKey: .artist)
        genre = try c.decode(String.self, forKey: .genre)
        duration = try c.decode(Int.self, forKey: .duration)
        streamURL = try c.decode(String.self, forKey: .streamURL)
        imageURL = try c.decodeIfPresent(String.self, forKey: .imageURL)
        isLocal = try c.decodeIfPresent(Bool.self, forKey: .isLocal) ?? false
        detailText = try c.decodeIfPresent(String.self, forKey: .detailText)
        externalURL = try c.decodeIfPresent(String.self, forKey: .externalURL)
        lyrics = try c.decodeIfPresent(String.self, forKey: .lyrics)
        commentCount = try c.decodeIfPresent(Int.self, forKey: .commentCount) ?? 0
        likeCount = try c.decodeIfPresent(Int.self, forKey: .likeCount) ?? 0
        isUserUploaded = try c.decodeIfPresent(Bool.self, forKey: .isUserUploaded) ?? isLocal
        artworkData = try c.decodeIfPresent(Data.self, forKey: .artworkData)
        initials = try c.decode(String.self, forKey: .initials)
        colorSeed = try c.decode(UInt.self, forKey: .colorSeed)
    }

    var playbackURL: URL? {
        if isLocal {
            return URL(fileURLWithPath: streamURL)
        }
        return URL(string: streamURL)
    }

    var artworkImage: UIImage? {
        guard let artworkData else { return nil }
        return UIImage(data: artworkData)
    }

    var durationText: String {
        let m = duration / 60
        let s = duration % 60
        return String(format: "%d:%02d", m, s)
    }
}

nonisolated struct Artist: Identifiable, Hashable {
    let id: String
    let name: String
    let genre: String
    let initials: String
    let colorSeed: UInt
    let trackIDs: [String]
}

nonisolated struct Album: Identifiable, Hashable {
    let id: String
    let title: String
    let artist: String
    let initials: String
    let colorSeed: UInt
    let trackIDs: [String]
}

enum Genre: String, CaseIterable, Identifiable {
    case pop = "Поп"
    case hipHop = "Хип-хоп"
    case rock = "Рок"
    case rap = "Рэп"
    case electronic = "Электроника"
    case rnb = "R&B"
    case indie = "Инди"
    case lofi = "Lo-Fi"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .pop: return "music.mic"
        case .hipHop: return "beats.headphones"
        case .rock: return "guitars"
        case .rap: return "waveform"
        case .electronic: return "dial.high"
        case .rnb: return "heart.text.square"
        case .indie: return "leaf"
        case .lofi: return "moon.stars"
        }
    }

    var aliases: [String] {
        switch self {
        case .pop: return [rawValue, "pop", "popular"]
        case .hipHop: return [rawValue, "hip hop", "hiphop", "hip-hop"]
        case .rock: return [rawValue, "rock"]
        case .rap: return [rawValue, "rap", "hip hop"]
        case .electronic: return [rawValue, "electronic", "edm", "dance"]
        case .rnb: return [rawValue, "r&b", "rnb"]
        case .indie: return [rawValue, "indie"]
        case .lofi: return [rawValue, "lofi", "lo-fi"]
        }
    }

    static func resolve(_ value: String) -> Genre? {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return allCases.first { genre in
            genre.aliases.contains { $0.lowercased() == normalized }
        }
    }

    /// Each genre maps to the green palette.
    var tint: Color {
        AuraColor.green
    }
}
