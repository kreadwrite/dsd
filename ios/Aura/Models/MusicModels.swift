//
//  MusicModels.swift
//  Aura
//

import SwiftUI
import UIKit

/// A playable track. Cover is either a remote image URL, local artwork data,
/// or a generated solid-colour placeholder built from the artist initials.
nonisolated struct Track: Identifiable, Hashable, Codable {
    let id: String
    let title: String
    let artist: String
    let genre: String
    /// Duration in seconds.
    let duration: Int
    /// Streamable audio URL or local file URL string.
    let streamURL: String
    /// Optional remote cover image URL.
    let imageURL: String?
    /// Two-letter initials used for the placeholder cover.
    let initials: String
    /// Hex colour seed for the placeholder cover gradient.
    let colorSeed: UInt
    /// Marks tracks imported by the user.
    let isLocal: Bool
    /// Optional extra text/notes for local tracks.
    let detailText: String?
    /// Optional inline cover art for local tracks.
    let artworkData: Data?

    init(
        id: String,
        title: String,
        artist: String,
        genre: String,
        duration: Int,
        streamURL: String,
        imageURL: String?,
        initials: String,
        colorSeed: UInt,
        isLocal: Bool = false,
        detailText: String? = nil,
        artworkData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.genre = genre
        self.duration = duration
        self.streamURL = streamURL
        self.imageURL = imageURL
        self.initials = initials
        self.colorSeed = colorSeed
        self.isLocal = isLocal
        self.detailText = detailText
        self.artworkData = artworkData
    }

    var durationText: String {
        let m = duration / 60
        let s = duration % 60
        return String(format: "%d:%02d", m, s)
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

nonisolated enum Genre: String, CaseIterable, Identifiable {
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

    var tint: Color {
        switch self {
        case .pop, .rap, .indie, .lofi: return AuraColor.green
        case .hipHop, .rock, .electronic, .rnb: return AuraColor.greenBright
        }
    }
}
