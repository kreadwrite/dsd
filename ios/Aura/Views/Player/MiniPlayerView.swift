//
//  MiniPlayerView.swift
//  Aura
//
//  Compact glass player shown above the tab bar on Home & Search.
//

import SwiftUI

struct MiniPlayerView: View {
    @ObservedObject private var player = AudioPlayerManager.shared
    let onExpand: () -> Void

    var body: some View {
        if let track = player.current {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    CoverArt(imageURL: track.imageURL, initials: track.initials, colorSeed: track.colorSeed, cornerRadius: 8)
                        .frame(width: 42, height: 42)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(track.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(AuraColor.textPrimary)
                            .lineLimit(1)
                        Text(track.artist)
                            .font(.system(size: 12))
                            .foregroundStyle(AuraColor.textSecondary)
                            .lineLimit(1)
                    }

                    Spacer(minLength: 6)

                    Button {
                        player.toggleFavorite(track)
                    } label: {
                        Image(systemName: player.isFavorite(track) ? "heart.fill" : "heart")
                            .font(.system(size: 17))
                            .foregroundStyle(player.isFavorite(track) ? AuraColor.green : AuraColor.textSecondary)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.plain)

                    Button {
                        player.togglePlayPause()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AuraColor.textPrimary)
                            .frame(width: 36, height: 36)
                            .contentTransition(.symbolEffect(.replace))
                    }
                    .buttonStyle(.plain)

                    Button {
                        player.next()
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(AuraColor.textPrimary)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

                // Slim progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.12))
                        Capsule().fill(AuraColor.green)
                            .frame(width: max(0, geo.size.width * player.progress))
                    }
                }
                .frame(height: 2)
                .padding(.horizontal, 12)
                .padding(.bottom, 7)
            }
            .auraGlass(in: .rect(cornerRadius: 18), interactive: true)
            .overlay(
                RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.08), lineWidth: 0.5)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                HapticManager.tap()
                onExpand()
            }
            .padding(.horizontal, 12)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
