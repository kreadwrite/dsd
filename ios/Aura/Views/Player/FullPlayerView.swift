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
        ZStack {
            backdrop

            VStack(spacing: 0) {
                grabber

                if let track = player.current {
                    Spacer(minLength: 10)

                    // Album art
                    CoverArt(imageURL: track.imageURL, initials: track.initials, colorSeed: track.colorSeed, cornerRadius: 24, showInitials: true)
                        .frame(width: 320, height: 320)
                        .frame(maxWidth: .infinity)
                        .shadow(color: Color(hex: track.colorSeed).opacity(0.5), radius: 30, y: 16)
                        .scaleEffect(player.isPlaying ? 1 : 0.92)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: player.isPlaying)
                        .padding(.horizontal, 30)

                    Spacer(minLength: 20)

                    // Title + like
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(track.title)
                                .font(.system(size: 26, weight: .heavy))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                            Text(track.artist)
                                .font(.system(size: 17))
                                .foregroundStyle(.white.opacity(0.7))
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
                    .padding(.horizontal, 32)

                    // Scrubber
                    scrubber.padding(.top, 22).padding(.horizontal, 28)

                    // Transport controls
                    controls.padding(.top, 18)

                    // Volume
                    volumeSlider.padding(.horizontal, 32).padding(.top, 26)

                    Spacer(minLength: 30)
                }
            }
        }
        .presentationDragIndicator(.hidden)
    }

    private var backdrop: some View {
        ZStack {
            Color.black
            if let track = player.current {
                CoverArt(imageURL: track.imageURL, initials: track.initials, colorSeed: track.colorSeed, cornerRadius: 0, showInitials: false)
                    .scaleEffect(1.4)
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
                HapticManager.tap(); dismiss()
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
        HStack(spacing: 28) {
            Button { player.toggleShuffle() } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(player.isShuffle ? AuraColor.green : .white.opacity(0.8))
            }

            Button { player.previous() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }

            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 74, height: 74)
                    .background(Circle().fill(AuraColor.green))
                    .contentTransition(.symbolEffect(.replace))
                    .shadow(color: AuraColor.green.opacity(0.5), radius: 16, y: 6)
            }

            Button { player.next() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.white)
            }

            Button { player.cycleRepeat() } label: {
                Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(player.repeatMode != .off ? AuraColor.green : .white.opacity(0.8))
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
