import SwiftUI

struct FullPlayerView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject private var player = AudioPlayerManager.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geo in
            ZStack {
                backdrop

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 18) {
                        grabber

                        if let track = player.current {
                            playerContent(track: track, size: coverSize(for: geo.size))
                                .padding(.top, 8)
                        } else {
                            Spacer(minLength: 260)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .presentationDragIndicator(.hidden)
    }

    private func coverSize(for size: CGSize) -> CGFloat {
        min(max(240, min(size.width - 64, 360)), size.height * 0.36)
    }

    @ViewBuilder
    private func playerContent(track: Track, size: CGFloat) -> some View {
        VStack(spacing: 18) {
            CoverArt(
                imageURL: track.imageURL,
                initials: track.initials,
                colorSeed: track.colorSeed,
                artworkData: track.artworkData,
                cornerRadius: 24,
                showInitials: true
            )
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity)
            .shadow(color: Color(hex: track.colorSeed).opacity(colorScheme == .dark ? 0.5 : 0.22), radius: 30, y: 16)
            .scaleEffect(player.isPlaying ? 1 : 0.95)
            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: player.isPlaying)

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(track.title)
                        .font(.system(size: 28, weight: .heavy, design: .rounded))
                        .foregroundStyle(AuraColor.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.75)
                    Text(track.artist)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(AuraColor.textSecondary)
                        .lineLimit(1)
                    if let detail = track.detailText, !detail.isEmpty {
                        Text(detail)
                            .font(.system(size: 14))
                            .foregroundStyle(AuraColor.textSecondary)
                            .lineLimit(3)
                    }
                }
                Spacer(minLength: 8)
                Button {
                    player.toggleFavorite(track)
                } label: {
                    Image(systemName: player.isFavorite(track) ? "heart.fill" : "heart")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(player.isFavorite(track) ? AuraColor.green : AuraColor.textPrimary)
                        .contentTransition(.symbolEffect(.replace))
                        .frame(width: 44, height: 44)
                }
            }

            Spacer(minLength: 30)

            scrubber

            Spacer(minLength: 20)

            controls

            Spacer(minLength: 20)

            volumeSlider
        }
        .padding(.top, 16)
    }

    private var backdrop: some View {
        ZStack {
            AuraColor.background
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
                .blur(radius: colorScheme == .dark ? 70 : 60)
                .opacity(colorScheme == .dark ? 0.55 : 0.22)

                LinearGradient(
                    colors: colorScheme == .dark
                    ? [.clear, .black.opacity(0.32), .black.opacity(0.82)]
                    : [.clear, AuraColor.background.opacity(0.72), AuraColor.background],
                    startPoint: .top,
                    endPoint: .bottom
                )
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
                    .foregroundStyle(AuraColor.textPrimary)
                    .frame(width: 40, height: 40)
                    .auraGlass(in: .circle, interactive: true)
            }
            Spacer()
            Text(settings.t(.nowPlaying))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(AuraColor.textSecondary)
                .textCase(.uppercase)
            Spacer()
            Menu {
                Button { player.cycleRepeat() } label: {
                    Label(settings.t(.queue), systemImage: "repeat")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(AuraColor.textPrimary)
                    .frame(width: 40, height: 40)
                    .auraGlass(in: .circle, interactive: true)
            }
        }
        .padding(.top, 4)
    }

    private var scrubber: some View {
        VStack(spacing: 6) {
            Slider(
                value: Binding(
                    get: { player.progress },
                    set: { player.seek(toProgress: $0) }
                ),
                in: 0...1
            )
            .tint(AuraColor.green)

            HStack {
                Text(player.currentTimeText)
                Spacer()
                Text(player.remainingTimeText)
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(AuraColor.textSecondary)
            .monospacedDigit()
        }
    }

    private var controls: some View {
        HStack(spacing: 22) {
            Button { player.toggleShuffle() } label: {
                Image(systemName: "shuffle")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(player.isShuffle ? AuraColor.green : AuraColor.textSecondary)
            }

            Button { player.previous() } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(AuraColor.textPrimary)
            }

            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 76, height: 76)
                    .background(Circle().fill(AuraColor.green))
                    .contentTransition(.symbolEffect(.replace))
                    .shadow(color: AuraColor.green.opacity(0.45), radius: 16, y: 6)
            }

            Button { player.next() } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(AuraColor.textPrimary)
            }

            Button { player.cycleRepeat() } label: {
                Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat")
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(player.repeatMode != .off ? AuraColor.green : AuraColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var volumeSlider: some View {
        HStack(spacing: 12) {
            Image(systemName: "speaker.fill")
                .font(.system(size: 13))
                .foregroundStyle(AuraColor.textSecondary)
            Slider(
                value: Binding(
                    get: { player.volume },
                    set: { player.setVolume($0) }
                ),
                in: 0...1
            )
            .tint(AuraColor.green)
            Image(systemName: "speaker.wave.3.fill")
                .font(.system(size: 13))
                .foregroundStyle(AuraColor.textSecondary)
        }
    }
}
