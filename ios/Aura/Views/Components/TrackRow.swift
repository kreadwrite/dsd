//
//  TrackRow.swift
//  Aura
//

import SwiftUI

struct TrackRow: View {
    let track: Track
    var trailingDuration: Bool = true
    @ObservedObject private var player = AudioPlayerManager.shared

    private var isCurrent: Bool { player.current?.id == track.id }

    var body: some View {
        HStack(spacing: 12) {
            CoverArt(imageURL: track.imageURL, initials: track.initials, colorSeed: track.colorSeed, artworkData: track.artworkData, cornerRadius: 8)
                .frame(width: 52, height: 52)
                .overlay {
                    if isCurrent {
                        ZStack {
                            Color.black.opacity(0.45)
                            Image(systemName: player.isPlaying ? "waveform" : "pause.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(AuraColor.green)
                                .symbolEffect(.variableColor.iterative, isActive: player.isPlaying)
                        }
                        .clipShape(.rect(cornerRadius: 8))
                    }
                }

            VStack(alignment: .leading, spacing: 3) {
                Text(track.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isCurrent ? AuraColor.green : AuraColor.textPrimary)
                    .lineLimit(1)
                Text(track.artist)
                    .font(.system(size: 13))
                    .foregroundStyle(AuraColor.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button {
                player.toggleFavorite(track)
            } label: {
                Image(systemName: player.isFavorite(track) ? "heart.fill" : "heart")
                    .font(.system(size: 15))
                    .foregroundStyle(player.isFavorite(track) ? AuraColor.green : AuraColor.textSecondary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)

            if trailingDuration {
                Text(track.durationText)
                    .font(.system(size: 13))
                    .foregroundStyle(AuraColor.textSecondary)
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
