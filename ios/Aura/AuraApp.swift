//
//  AuraApp.swift
//  Aura
//

import SwiftUI

@main
struct AuraApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var player = AudioPlayerManager.shared
    @StateObject private var library = LocalMusicLibrary.shared
    @State private var showOnboarding = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environmentObject(settings)
                    .environmentObject(player)
                    .environmentObject(library)

                if showOnboarding {
                    OnboardingView { withAnimation(.easeInOut(duration: 0.45)) { showOnboarding = false } }
                        .environmentObject(settings)
                        .transition(.opacity)
                        .zIndex(10)
                }
            }
            .preferredColorScheme(settings.theme.colorScheme)
            .tint(AuraColor.green)
            .onAppear {
                player.attach(settings: settings)
                player.attach(library: library)
                showOnboarding = !settings.hasOnboarded
                NotificationManager.scheduleDaily(
                    minutes: settings.reminderMinutes,
                    enabled: settings.notificationsEnabled
                )
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    player.reactivateSession()
                }
            }
        }
    }
}
