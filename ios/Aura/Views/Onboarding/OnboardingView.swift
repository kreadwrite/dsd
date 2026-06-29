//
//  OnboardingView.swift
//  Aura
//
//  Full-screen, swipeable 3-page onboarding shown only on first launch.
//

import SwiftUI

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let image: String
    let symbol: String
    let title: LKey
    let body: LKey
    let accent: Color
}

struct OnboardingView: View {
    @EnvironmentObject private var settings: AppSettings
    let onFinish: () -> Void

    @State private var index = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(image: "soundwave_liquid_glass_bg", symbol: "waveform", title: .onb1Title, body: .onb1Body, accent: AuraColor.green),
        OnboardingPage(image: "soundwave_glass_liquid", symbol: "sparkles", title: .onb2Title, body: .onb2Body, accent: AuraColor.greenBright),
        OnboardingPage(image: "glowing_ribbons_ambient", symbol: "circle.hexagongrid.fill", title: .onb3Title, body: .onb3Body, accent: AuraColor.green)
    ]

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            TabView(selection: $index) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { i, page in
                    pageView(page).tag(i)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: index)

            VStack {
                HStack {
                    Spacer()
                    if index < pages.count - 1 {
                        Button(settings.t(.onbSkip)) {
                            finish()
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.8))
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .auraGlass(in: .capsule)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                Spacer()

                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == index ? pages[index].accent : Color.white.opacity(0.3))
                            .frame(width: i == index ? 26 : 8, height: 8)
                            .animation(.spring(response: 0.4, dampingFraction: 0.7), value: index)
                    }
                }
                .padding(.bottom, 24)

                // Primary action
                Button {
                    if index < pages.count - 1 {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { index += 1 }
                        HapticManager.tap()
                    } else {
                        finish()
                    }
                } label: {
                    Text(index < pages.count - 1 ? settings.t(.onbNext) : settings.t(.onbStart))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                        .background(Capsule().fill(pages[index].accent))
                        .shadow(color: pages[index].accent.opacity(0.5), radius: 16, y: 8)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 40)
                .animation(.easeInOut, value: index)
            }
        }
    }

    @ViewBuilder
    private func pageView(_ page: OnboardingPage) -> some View {
        ZStack {
            Image(page.image)
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.1), .black.opacity(0.55), .black],
                        startPoint: .top, endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )

            VStack(alignment: .leading, spacing: 18) {
                Spacer()
                Image(systemName: page.symbol)
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(page.accent)
                    .shadow(color: page.accent.opacity(0.6), radius: 14)

                Text(settings.t(page.title))
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)

                Text(settings.t(page.body))
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(.white.opacity(0.78))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer().frame(height: 200)
            }
            .padding(.horizontal, 30)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func finish() {
        HapticManager.success()
        settings.hasOnboarded = true
        onFinish()
    }
}
