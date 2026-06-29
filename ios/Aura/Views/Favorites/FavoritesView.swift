//
//  FavoritesView.swift
//  Aura
//

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject private var player = AudioPlayerManager.shared

    private var tracks: [Track] { player.favoriteTracks }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if tracks.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 2) {
                        ForEach(tracks) { track in
                            Button {
                                player.play(track: track, in: tracks)
                            } label: { TrackRow(track: track) }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Color.clear.frame(height: 70)
            }
        }
        .scrollIndicators(.hidden)
        .background(AppBackground())
        .navigationTitle(settings.t(.favorites))
        .navigationBarTitleDisplayMode(.large)
    }

    private var header: some View {
        HStack(spacing: 16) {
            ZStack {
                LinearGradient(colors: [AuraColor.green, AuraColor.greenBright],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                Image(systemName: "heart.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 110, height: 110)
            .clipShape(.rect(cornerRadius: 18))
            .shadow(color: AuraColor.green.opacity(0.4), radius: 14, y: 6)

            VStack(alignment: .leading, spacing: 6) {
                Text(settings.t(.likedTracks))
                    .font(.system(size: 22, weight: .heavy))
                    .foregroundStyle(AuraColor.textPrimary)
                Text("\(tracks.count) \(settings.t(.tracksCount))")
                    .font(.system(size: 14))
                    .foregroundStyle(AuraColor.textSecondary)

                if !tracks.isEmpty {
                    Button {
                        if let first = tracks.first { player.play(track: first, in: tracks) }
                    } label: {
                        Label("", systemImage: "play.fill")
                            .labelStyle(.iconOnly)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.black)
                            .padding(12)
                            .background(Circle().fill(AuraColor.green))
                    }
                    .padding(.top, 2)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "heart.slash")
                .font(.system(size: 52))
                .foregroundStyle(AuraColor.textSecondary)
            Text(settings.t(.emptyFavorites))
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AuraColor.textPrimary)
            Text(settings.t(.emptyFavoritesBody))
                .font(.system(size: 15))
                .foregroundStyle(AuraColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
        .padding(.horizontal, 40)
    }
}
