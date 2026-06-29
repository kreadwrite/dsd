//
//  RootView.swift
//  Aura
//
//  Home / Search / Profile are the main tabs. The mini-player is an overlay
//  above the tab bar so it never stretches the tab layout.
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if player.current != nil {
                MiniPlayerHost { showFullPlayer = true }
                    .padding(.bottom, 8)
            }
        }
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
            Tab(settings.t(.profile), systemImage: "person.fill") {
                NavigationStack { ProfileView() }
            }
            Tab(settings.t(.search), systemImage: "magnifyingglass", role: .search) {
                NavigationStack { SearchView() }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }

    // MARK: - Fallback Tabs

    private var legacyTabs: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label(settings.t(.home), systemImage: "house.fill") }
            NavigationStack { ProfileView() }
                .tabItem { Label(settings.t(.profile), systemImage: "person.fill") }
            NavigationStack { SearchView() }
                .tabItem { Label(settings.t(.search), systemImage: "magnifyingglass") }
        }
    }
}

private struct MiniPlayerHost: View {
    @ObservedObject private var player = AudioPlayerManager.shared
    let onExpand: () -> Void

    var body: some View {
        if player.current != nil {
            MiniPlayerView(onExpand: onExpand)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
        } else {
            EmptyView()
        }
    }
}
