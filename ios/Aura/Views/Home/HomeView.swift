//
//  HomeView.swift
//  Aura
//

import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var recommendations: [Track] = MusicCatalog.recommendations
    @Published var recentlyPlayed: [Track] = MusicCatalog.recentlyPlayed
    @Published var popularFromJamendo: [Track] = []
    @Published var isLoading = false

    func load() async {
        isLoading = true
        let popular = await JamendoService.popular(limit: 16)
        if !popular.isEmpty {
            popularFromJamendo = popular
            recommendations = Array(popular.prefix(8))
        }
        isLoading = false
    }
}

struct HomeView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject private var player = AudioPlayerManager.shared
    @StateObject private var vm = HomeViewModel()

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let key: LKey = hour < 12 ? .goodMorning : (hour < 18 ? .goodAfternoon : .goodEvening)
        return settings.t(key)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                // Greeting header
                VStack(alignment: .leading, spacing: 4) {
                    Text(greeting)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AuraColor.textSecondary)
                    Text(settings.userName)
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(AuraColor.textPrimary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                rail(title: settings.t(.recentlyPlayed)) {
                    ForEach(vm.recentlyPlayed) { track in
                        Button {
                            player.play(track: track, in: vm.recentlyPlayed)
                        } label: { TrackCard(track: track) }
                        .buttonStyle(PressableStyle())
                    }
                }

                rail(title: settings.t(.recommendations)) {
                    ForEach(vm.recommendations) { track in
                        Button {
                            player.play(track: track, in: vm.recommendations)
                        } label: { TrackCard(track: track) }
                        .buttonStyle(PressableStyle())
                    }
                }

                rail(title: settings.t(.popularAlbums)) {
                    ForEach(MusicCatalog.albums) { album in
                        Button {
                            let tracks = MusicCatalog.tracks(ids: album.trackIDs)
                            if let first = tracks.first { player.play(track: first, in: tracks) }
                        } label: { AlbumCard(album: album) }
                        .buttonStyle(PressableStyle())
                    }
                }

                rail(title: settings.t(.topArtists)) {
                    ForEach(MusicCatalog.artists) { artist in
                        Button {
                            let tracks = MusicCatalog.tracks(ids: artist.trackIDs)
                            if let first = tracks.first { player.play(track: first, in: tracks) }
                        } label: { ArtistCard(artist: artist) }
                        .buttonStyle(PressableStyle())
                    }
                }

                Color.clear.frame(height: 150) // space for mini-player + tab bar
            }
        }
        .scrollIndicators(.hidden)
        .background(AppBackground())
        .navigationTitle(settings.t(.home))
        .navigationBarTitleDisplayMode(.inline)
        .task { await vm.load() }
    }

    @ViewBuilder
    private func rail<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: title)
            ScrollView(.horizontal) {
                HStack(spacing: 16) { content() }
                .padding(.horizontal, 20)
            }
            .scrollIndicators(.hidden)
        }
    }
}

/// Subtle press-scale animation for tappable cards.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

/// Shared ambient wallpaper background.
struct AppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            AuraColor.background.ignoresSafeArea()
            if colorScheme == .dark {
                Image("dark_music_app_bg")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.55)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            } else {
                LinearGradient(
                    colors: [AuraColor.background, AuraColor.surface.opacity(0.9), AuraColor.background],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .allowsHitTesting(false)
                Image("glowing_ribbons_ambient")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.18)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }
}
