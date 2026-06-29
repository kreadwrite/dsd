//
//  FullPlayerView.swift
//  Aura
//
//  Full-screen now-playing experience with blurred album backdrop, scrubber,
//  volume slider, shuffle / repeat and like.
//

import SwiftUI

struct FullPlayerView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject private var player = AudioPlayerManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isScrubbing = false
    @State private var scrubValue: Double = 0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backdrop

                VStack(spacing: 0) {
                    grabber

                    if let track = player.current {
                        Spacer(minLength: compactSpacing(for: geo.size) * 1.5)

                        CoverArt(
                            imageURL: track.imageURL,
                            initials: track.initials,
                            colorSeed: track.colorSeed,
                            artworkData: track.artworkData,
                            cornerRadius: 28,
                            showInitials: true
                        )
                        .frame(width: coverSize(for: geo.size), height: coverSize(for: geo.size))
                        .frame(maxWidth: .infinity)
                        .shadow(color: Color(hex: track.colorSeed).opacity(0.45), radius: 28, y: 14)
                        .scaleEffect(player.isPlaying ? 1.0 : 0.95)
                        .animation(.spring(response: 0.45, dampingFraction: 0.72), value: player.isPlaying)
                        .padding(.horizontal, 24)

                        Spacer(minLength: compactSpacing(for: geo.size))

                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(track.title)
                                    .font(.system(size: titleFontSize(for: geo.size), weight: .heavy))
                                    .foregroundStyle(.white)
                                    .lineLimit(1)
                                Text(track.artist)
                                    .font(.system(size: 17))
                                    .foregroundStyle(.white.opacity(0.72))
                                    .lineLimit(1)
                            }

                            Spacer()

                            Button {
                                player.toggleFavorite(track)
                            } label: {
                                Image(systemName: player.isFavorite(track) ? "heart.fill" : "heart")
                                    .font(.system(size: 24))
                                    .foregroundStyle(player.isFavorite(track) ? AuraColor.green : .white)
                                    .contentTransition(.symbolEffect(.replace))
                            }
                        }
                        .padding(.horizontal, 28)

                        Spacer(minLength: compactSpacing(for: geo.size) * 0.8)

                        scrubber
                            .padding(.horizontal, 24)

                        Spacer(minLength: compactSpacing(for: geo.size) * 0.55)

                        controls
                            .padding(.horizontal, 20)

                        Spacer(minLength: compactSpacing(for: geo.size) * 0.55)

                        volumeSlider
                            .padding(.horizontal, 28)

                        Spacer(minLength: 12)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, 10)
                .padding(.bottom, 18)
            }
        }
        .presentationDragIndicator(.hidden)
    }

    private func coverSize(for size: CGSize) -> CGFloat {
        min(size.width - 64, max(220, size.height * 0.34))
    }

    private func titleFontSize(for size: CGSize) -> CGFloat {
        size.height < 760 ? 22 : 26
    }

    private func compactSpacing(for size: CGSize) -> CGFloat {
        size.height < 760 ? 12 : 18
    }

    private var backdrop: some View {
        ZStack {
            Color.black
            if let track = player.current {
                CoverArt(
                    imageURL: track.imageURL,
                    initials: track.initials,
                    colorSeed: track.colorSeed,
                    artworkData: track.artworkData,
                    cornerRadius: 0,
                    showInitials: false
                )
                .scaleEffect(1.35)
                .blur(radius: 70)
                .opacity(0.7)
                LinearGradient(colors: [.clear, .black.opacity(0.5), .black],
                               startPoint: .top, endPoint: .bottom)
            }
        }
        .ignoresSafeArea()
    }

    private var grabber: some View {
        HStack {
            Button {
                HapticManager.tap()
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .auraGlass(in: .circle, interactive: true)
            }

            Spacer()

            Text(settings.t(.nowPlaying))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .textCase(.uppercase)

            Spacer()

            Menu {
                Button { player.cycleRepeat() } label: {
                    Label(settings.t(.queue), systemImage: "repeat")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .auraGlass(in: .circle, interactive: true)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
    }

    private var scrubber: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { isScrubbing ? scrubValue : player.progress },
                    set: { scrubValue = $0 }
                ),
                in: 0...1,
                onEditingChanged: { editing in
                    isScrubbing = editing
                    if !editing { player.seek(toProgress: scrubValue) }
                }
            )
            .tint(AuraColor.green)

            HStack {
                Text(player.currentTimeText)
                Spacer()
                Text(player.remainingTimeText)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(.white.opacity(0.6))
            .monospacedDigit()
        }
    }

    private var controls: some View {
        HStack(spacing: 24) {
            Button { player.toggleShuffle() } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(player.isShuffle ? AuraColor.green : .white.opacity(0.82))
            }

            Button { player.previous() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(.white)
            }

            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 29, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(AuraColor.green))
                    .contentTransition(.symbolEffect(.replace))
                    .shadow(color: AuraColor.green.opacity(0.45), radius: 16, y: 6)
            }

            Button { player.next() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 25, weight: .bold))
                    .foregroundStyle(.white)
            }

            Button { player.cycleRepeat() } label: {
                Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(player.repeatMode != .off ? AuraColor.green : .white.opacity(0.82))
            }
        }
    }

    private var volumeSlider: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
            Slider(value: Binding(
                get: { player.volume },
                set: { player.setVolume($0) }
            ), in: 0...1)
            .tint(.white)
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.6))
        }
    }
}
