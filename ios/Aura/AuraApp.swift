//
//  AuraApp.swift
//  Aura
//

import SwiftUI

@main
struct AuraApp: App {
    @StateObject private var settings = AppSettings()
    @StateObject private var player = AudioPlayerManager.shared
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    .environmentObject(settings)
                    .environmentObject(player)

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
                showOnboarding = !settings.hasOnboarded
                NotificationManager.scheduleDaily(
                    minutes: settings.reminderMinutes,
                    enabled: settings.notificationsEnabled
                )
            }
        }
    }
}
