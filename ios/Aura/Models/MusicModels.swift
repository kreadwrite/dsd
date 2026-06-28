//
//  MusicModels.swift
//  Aura
//

import SwiftUI

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
    /// Two-letter initials used for the placeholder cover.
    let initials: String
    /// Hex colour seed for the placeholder cover gradient.
    let colorSeed: UInt

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

    /// Each genre maps to either green or blue from the palette.
    var tint: Color {
        switch self {
        case .pop, .rap, .indie, .lofi: return AuraColor.green
        case .hipHop, .rock, .electronic, .rnb: return AuraColor.blue
        }
    }
}
