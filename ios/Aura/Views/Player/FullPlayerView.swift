import SwiftUI

struct FullPlayerView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject private var player = AudioPlayerManager.shared
    @ObservedObject private var social = SocialStore.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var showSocialSheet = false
    @State private var socialMode: PlayerSocialMode = .lyrics

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
                    .frame(maxWidth: min(geo.size.width - 40, 360))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
            }
        }
        .presentationDragIndicator(.hidden)
        .sheet(isPresented: $showSocialSheet) {
            if let track = player.current {
                PlayerSocialSheet(track: track, mode: $socialMode)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    private func coverSize(for size: CGSize) -> CGFloat {
        min(max(210, min(size.width - 92, 292)), size.height * 0.30)
    }

    @ViewBuilder
    private func playerContent(track: Track, size: CGFloat) -> some View {
        VStack(spacing: 16) {
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
            .shadow(color: AuraColor.green.opacity(colorScheme == .dark ? 0.35 : 0.18), radius: 28, y: 14)
            .scaleEffect(player.isPlaying ? 1 : 0.95)
            .animation(.spring(response: 0.5, dampingFraction: 0.75), value: player.isPlaying)
            .frame(maxWidth: .infinity)

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
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 30)

            scrubber

            Spacer(minLength: 20)

            controls

            Spacer(minLength: 20)

            volumeSlider

            actionRow(track)
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
        .frame(maxWidth: .infinity)
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

    private func actionRow(_ track: Track) -> some View {
        HStack(spacing: 26) {
            Button { player.toggleFavorite(track) } label: {
                Image(systemName: player.isFavorite(track) ? "heart.fill" : "heart")
                    .foregroundStyle(player.isFavorite(track) ? AuraColor.green : AuraColor.textSecondary)
            }
            Button {
                socialMode = .comments
                showSocialSheet = true
            } label: {
                Image(systemName: "bubble.left.and.bubble.right")
                    .foregroundStyle(AuraColor.textSecondary)
            }
            ShareLink(item: shareText(for: track)) {
                Image(systemName: "airplayaudio")
                    .foregroundStyle(AuraColor.textSecondary)
            }
            Button { player.next() } label: {
                Image(systemName: "forward.end")
                    .foregroundStyle(AuraColor.textSecondary)
            }
            Menu {
                Button {
                    socialMode = .lyrics
                    showSocialSheet = true
                } label: {
                    Label("Текст", systemImage: "text.quote")
                }
                Button {
                    socialMode = .comments
                    showSocialSheet = true
                } label: {
                    Label("Комментарии", systemImage: "bubble.left")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(AuraColor.textSecondary)
            }
        }
        .font(.system(size: 20, weight: .semibold))
        .frame(maxWidth: .infinity)
        .padding(.top, 2)
    }

    private func shareText(for track: Track) -> String {
        track.externalURL ?? track.streamURL
    }
}

private enum PlayerSocialMode: String, CaseIterable {
    case lyrics = "Текст"
    case comments = "Комментарии"
}

private struct PlayerSocialSheet: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject private var social = SocialStore.shared
    let track: Track
    @Binding var mode: PlayerSocialMode

    @State private var draft = ""
    @State private var replyTarget: TrackComment?

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("", selection: $mode) {
                    ForEach(PlayerSocialMode.allCases, id: \.self) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 18)
                .padding(.top, 12)

                if mode == .lyrics {
                    lyricsView
                } else {
                    commentsView
                }
            }
            .background(AppBackground())
            .navigationTitle(track.title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var lyricsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                let text = (track.lyrics ?? track.detailText ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                if text.isEmpty {
                    Text("Текст появится, когда он будет добавлен к треку.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(AuraColor.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 220, alignment: .center)
                } else {
                    ForEach(Array(text.components(separatedBy: .newlines).filter { !$0.isEmpty }.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(.system(size: 22, weight: index == 0 ? .heavy : .semibold, design: .rounded))
                            .foregroundStyle(index == 0 ? AuraColor.green : AuraColor.textPrimary)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                }
            }
            .padding(20)
        }
        .animation(.easeInOut(duration: 0.28), value: track.id)
    }

    private var commentsView: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    ForEach(social.comments(for: track.id)) { comment in
                        commentRow(comment)
                    }
                }
                .padding(18)
            }
            commentComposer
        }
    }

    private func commentRow(_ comment: TrackComment) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Circle()
                    .fill(AuraColor.green.opacity(0.18))
                    .frame(width: 34, height: 34)
                    .overlay(Text(String(comment.userName.prefix(1))).font(.system(size: 14, weight: .bold)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(comment.userName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AuraColor.textPrimary)
                    Text(comment.createdAt, style: .relative)
                        .font(.system(size: 11))
                        .foregroundStyle(AuraColor.textSecondary)
                }
                Spacer()
            }
            if let parentID = comment.parentID,
               let parent = social.comments(for: track.id).first(where: { $0.id == parentID }) {
                Text("Ответ для @\(parent.userName)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AuraColor.green)
            }
            Text(comment.text)
                .font(.system(size: 15))
                .foregroundStyle(AuraColor.textPrimary)
            HStack(spacing: 18) {
                Button("Ответить") { replyTarget = comment }
                Button {
                    social.likeComment(comment)
                } label: {
                    Label("\(comment.likeCount)", systemImage: "hand.thumbsup")
                }
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(AuraColor.green)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(AuraColor.surface.opacity(0.72)))
    }

    private var commentComposer: some View {
        VStack(spacing: 8) {
            if let replyTarget {
                HStack {
                    Text("Ответ для @\(replyTarget.userName)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(AuraColor.green)
                    Spacer()
                    Button { self.replyTarget = nil } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .foregroundStyle(AuraColor.textSecondary)
                }
            }
            HStack(spacing: 10) {
                TextField("Написать комментарий...", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 11)
                    .background(Capsule().fill(AuraColor.surface))
                Button {
                    social.addComment(trackID: track.id, userName: settings.userName, text: draft, parentID: replyTarget?.id)
                    draft = ""
                    replyTarget = nil
                } label: {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.black)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(AuraColor.green))
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(14)
        .background(.ultraThinMaterial)
    }
}
