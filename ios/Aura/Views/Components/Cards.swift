//
//  Cards.swift
//  Aura
//

import SwiftUI

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(AuraColor.textPrimary)
            .padding(.horizontal, 20)
    }
}

/// Large square card used in horizontal rails (recommendations / recently played).
struct TrackCard: View {
    let track: Track
    var size: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CoverArt(imageURL: track.imageURL, initials: track.initials, colorSeed: track.colorSeed, artworkData: track.artworkData, cornerRadius: 16)
                .frame(width: size, height: size)
                .shadow(color: Color(hex: track.colorSeed).opacity(0.3), radius: 12, y: 6)

            Text(track.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AuraColor.textPrimary)
                .lineLimit(1)
            Text(track.artist)
                .font(.system(size: 13))
                .foregroundStyle(AuraColor.textSecondary)
                .lineLimit(1)
        }
        .frame(width: size)
    }
}

/// Circular artist card.
struct ArtistCard: View {
    let artist: Artist
    var size: CGFloat = 130

    var body: some View {
        VStack(spacing: 10) {
            CoverArt(imageURL: nil, initials: artist.initials, colorSeed: artist.colorSeed,
                     cornerRadius: size / 2, symbol: "person.fill")
                .frame(width: size, height: size)
                .clipShape(Circle())
                .shadow(color: Color(hex: artist.colorSeed).opacity(0.3), radius: 10, y: 5)

            Text(artist.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AuraColor.textPrimary)
                .lineLimit(1)
            Text(artist.genre)
                .font(.system(size: 12))
                .foregroundStyle(AuraColor.textSecondary)
                .lineLimit(1)
        }
        .frame(width: size)
    }
}

/// Album card.
struct AlbumCard: View {
    let album: Album
    var size: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            CoverArt(imageURL: nil, initials: album.initials, colorSeed: album.colorSeed, cornerRadius: 16, symbol: "opticaldisc")
                .frame(width: size, height: size)
                .shadow(color: Color(hex: album.colorSeed).opacity(0.3), radius: 12, y: 6)

            Text(album.title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AuraColor.textPrimary)
                .lineLimit(1)
            Text(album.artist)
                .font(.system(size: 13))
                .foregroundStyle(AuraColor.textSecondary)
                .lineLimit(1)
        }
        .frame(width: size)
    }
}

/// Genre pill button (capsule with glass).
struct GenrePill: View {
    let title: String
    let isSelected: Bool
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(isSelected ? .black : AuraColor.textPrimary)
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
        }
        .background {
            if isSelected {
                Capsule().fill(tint)
            } else {
                Capsule().fill(AuraColor.surface)
            }
        }
        .overlay(Capsule().stroke(.white.opacity(0.06), lineWidth: 0.5))
    }
}
