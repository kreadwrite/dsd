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
    /// Optional imported artwork stored in the sandbox.
    let artworkData: Data?
    /// Two-letter initials used for the placeholder cover.
    let initials: String
    /// Hex colour seed for the placeholder cover gradient.
    let colorSeed: UInt

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
