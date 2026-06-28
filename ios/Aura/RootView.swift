//
//  RootView.swift
//  Aura
//
//  Liquid Glass tab bar. Home / Favorites / Profile are grouped, while Search
//  sits in its own glass capsule (iOS 26 `.search` tab role), and the
//  mini-player floats as the tab-bar bottom accessory.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject private var player = AudioPlayerManager.shared
    @State private var showFullPlayer = false

    var body: some View {
        Group {
            if #available(iOS 26.0, *) {
                modernTabs
            } else {
                legacyTabs
            }
        }
        .tint(AuraColor.green)
        .fullScreenCover(isPresented: $showFullPlayer) {
            FullPlayerView()
        }
    }

    // MARK: - iOS 26 Tabs

    @available(iOS 26.0, *)
    private var modernTabs: some View {
        TabView {
            Tab(settings.t(.home), systemImage: "house.fill") {
                NavigationStack { HomeView() }
            }
            Tab(settings.t(.favorites), systemImage: "heart.fill") {
                NavigationStack { FavoritesView() }
            }
            Tab(settings.t(.profile), systemImage: "person.fill") {
                NavigationStack { ProfileView() }
            }
            Tab(settings.t(.search), systemImage: "magnifyingglass", role: .search) {
                NavigationStack { SearchView() }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            MiniPlayerAccessory { showFullPlayer = true }
        }
    }

    // MARK: - Fallback Tabs

    private var legacyTabs: some View {
        ZStack(alignment: .bottom) {
            TabView {
                NavigationStack { HomeView() }
                    .tabItem { Label(settings.t(.home), systemImage: "house.fill") }
                NavigationStack { FavoritesView() }
                    .tabItem { Label(settings.t(.favorites), systemImage: "heart.fill") }
                NavigationStack { SearchView() }
                    .tabItem { Label(settings.t(.search), systemImage: "magnifyingglass") }
                NavigationStack { ProfileView() }
                    .tabItem { Label(settings.t(.profile), systemImage: "person.fill") }
            }

            if player.current != nil {
                MiniPlayerView { showFullPlayer = true }
                    .padding(.bottom, 52)
            }
        }
    }
}

/// Wrapper that renders the mini-player inside the iOS 26 bottom accessory slot.
private struct MiniPlayerAccessory: View {
    @ObservedObject private var player = AudioPlayerManager.shared
    let onExpand: () -> Void

    var body: some View {
        if let track = player.current {
            HStack(spacing: 12) {
                CoverArt(imageURL: track.imageURL, initials: track.initials, colorSeed: track.colorSeed, cornerRadius: 7)
                    .frame(width: 36, height: 36)
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
                Spacer(minLength: 4)
                Button {
                    player.togglePlayPause()
                } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AuraColor.textPrimary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                Button {
                    player.next()
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(AuraColor.textPrimary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .contentShape(Rectangle())
            .onTapGesture { HapticManager.tap(); onExpand() }
        } else {
            EmptyView()
        }
    }
}
