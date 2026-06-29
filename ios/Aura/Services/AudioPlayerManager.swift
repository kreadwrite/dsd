//
//  AudioPlayerManager.swift
//  Aura
//
//  AVPlayer-based playback engine with background audio, lock-screen controls,
//  queue management, shuffle / repeat and progress tracking.
//

import Foundation
import AVFoundation
import MediaPlayer
import Combine
import UIKit

enum RepeatMode: String { case off, all, one }

@MainActor
final class AudioPlayerManager: ObservableObject {
    static let shared = AudioPlayerManager()

    @Published private(set) var current: Track?
    @Published private(set) var isPlaying = false
    @Published var progress: Double = 0
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var volume: Double = 0.8
    @Published var isShuffle = false
    @Published var repeatMode: RepeatMode = .off
    @Published private(set) var favorites: Set<String> = []

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var queue: [Track] = []
    private var index = 0
    private weak var settings: AppSettings?
    private weak var library: LocalMusicLibrary?
    private let favoritesKey = "favoriteTrackIDs"

    private var listeningAccumulator: Double = 0
    private var lastObservedPlaybackTime: Double?

    private init() {
        configureSession()
        configureRemoteCommands()
        observeAudioSessionNotifications()
        loadFavorites()
    }

    func attach(settings: AppSettings) {
        self.settings = settings
    }

    func attach(library: LocalMusicLibrary) {
        self.library = library
    }

    func reactivateSession() {
        configureSession()
        if isPlaying {
            player?.play()
        }
    }

    // MARK: - Session

    private func configureSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetoothA2DP])
            try session.setActive(true)
        } catch {
            print("Audio session error: \(error.localizedDescription)")
        }
    }

    private func observeAudioSessionNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioInterruption(_:)),
            name: AVAudioSession.interruptionNotification,
            object: AVAudioSession.sharedInstance()
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: AVAudioSession.sharedInstance()
        )
    }

    @objc private func handleAudioInterruption(_ note: Notification) {
        guard let info = note.userInfo,
              let rawValue = info[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: rawValue) else { return }

        switch type {
        case .began:
            commitListeningProgress(force: true)
            player?.pause()
            isPlaying = false
            updateNowPlaying()
        case .ended:
            reactivateSession()
            if let optionsValue = info[AVAudioSessionInterruptionOptionKey] as? UInt,
               AVAudioSession.InterruptionOptions(rawValue: optionsValue).contains(.shouldResume) {
                player?.play()
                isPlaying = true
                updateNowPlaying()
            }
        @unknown default:
            break
        }
    }

    @objc private func handleRouteChange(_ note: Notification) {
        guard let reasonRaw = note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonRaw) else { return }
        if reason == .oldDeviceUnavailable {
            commitListeningProgress(force: true)
            player?.pause()
            isPlaying = false
            updateNowPlaying()
        }
    }

    // MARK: - Queue control

    func play(track: Track, in tracks: [Track]) {
        queue = tracks.isEmpty ? [track] : tracks
        index = queue.firstIndex(of: track) ?? 0
        startCurrent()
    }

    func playSingle(_ track: Track) {
        play(track: track, in: [track])
    }

    private func startCurrent() {
        guard queue.indices.contains(index) else { return }
        commitListeningProgress()

        let track = queue[index]
        current = track
        duration = Double(track.duration)
        progress = 0
        currentTime = 0
        listeningAccumulator = 0
        lastObservedPlaybackTime = nil

        guard let url = track.playbackURL else { return }
        if let observer = timeObserver { player?.removeTimeObserver(observer); timeObserver = nil }
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)

        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player?.volume = Float(volume)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(itemDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: item
        )

        addTimeObserver()
        reactivateSession()
        player?.play()
        isPlaying = true
        updateNowPlaying()
        HapticManager.tap()
    }

    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                let seconds = time.seconds
                guard seconds.isFinite else { return }
                if let last = self.lastObservedPlaybackTime, self.isPlaying {
                    let delta = seconds - last
                    if delta > 0, delta < 5 {
                        self.listeningAccumulator += delta
                        self.commitListeningProgress(force: false)
                    }
                }
                self.lastObservedPlaybackTime = seconds
                self.currentTime = seconds
                if let dur = self.player?.currentItem?.duration.seconds, dur.isFinite, dur > 0 {
                    self.duration = dur
                    self.progress = min(max(seconds / dur, 0), 1)
                }
                self.updateNowPlayingTime()
            }
        }
    }

    @objc private func itemDidFinish() {
        commitListeningProgress(force: true)
        switch repeatMode {
        case .one:
            seek(to: 0)
            player?.play()
            isPlaying = true
        default:
            next()
        }
    }

    private func commitListeningProgress(force: Bool = false) {
        let whole = Int(listeningAccumulator)
        guard whole > 0 || force else { return }
        if whole > 0 {
            settings?.registerListening(seconds: whole, genre: current?.genre)
            listeningAccumulator -= Double(whole)
        }
    }

    // MARK: - Transport

    func togglePlayPause() {
        guard player != nil else {
            if let track = current { playSingle(track) }
            return
        }
        if isPlaying {
            commitListeningProgress(force: true)
            player?.pause()
            isPlaying = false
        } else {
            reactivateSession()
            player?.play()
            isPlaying = true
            lastObservedPlaybackTime = currentTime
        }
        updateNowPlaying()
        HapticManager.tap()
    }

    func next() {
        guard !queue.isEmpty else { return }
        commitListeningProgress(force: true)
        if isShuffle {
            index = Int.random(in: 0..<queue.count)
        } else if index + 1 < queue.count {
            index += 1
        } else if repeatMode == .all {
            index = 0
        } else {
            player?.pause()
            isPlaying = false
            updateNowPlaying()
            return
        }
        startCurrent()
    }

    func previous() {
        guard !queue.isEmpty else { return }
        if currentTime > 3 {
            seek(to: 0)
            return
        }
        commitListeningProgress(force: true)
        index = index > 0 ? index - 1 : queue.count - 1
        startCurrent()
    }

    func seek(to seconds: Double) {
        player?.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
        currentTime = seconds
        lastObservedPlaybackTime = seconds
        if duration > 0 { progress = seconds / duration }
        updateNowPlayingTime()
    }

    func seek(toProgress p: Double) {
        seek(to: p * duration)
    }

    func setVolume(_ v: Double) {
        volume = v
        player?.volume = Float(v)
    }

    func toggleShuffle() { isShuffle.toggle(); HapticManager.selection() }

    func cycleRepeat() {
        switch repeatMode {
        case .off: repeatMode = .all
        case .all: repeatMode = .one
        case .one: repeatMode = .off
        }
        HapticManager.selection()
    }

    // MARK: - Favorites

    func isFavorite(_ track: Track) -> Bool { favorites.contains(track.id) }

    func toggleFavorite(_ track: Track) {
        if favorites.contains(track.id) {
            favorites.remove(track.id)
        } else {
            favorites.insert(track.id)
            HapticManager.success()
        }
        saveFavorites()
    }

    var favoriteTracks: [Track] {
        favorites.compactMap { id in
            MusicCatalog.track(id: id)
                ?? library?.track(id: id)
                ?? (current?.id == id ? current : nil)
        }
    }

    private func loadFavorites() {
        let ids = UserDefaults.standard.stringArray(forKey: favoritesKey) ?? []
        favorites = Set(ids)
    }

    private func saveFavorites() {
        UserDefaults.standard.set(Array(favorites), forKey: favoritesKey)
    }

    // MARK: - Now Playing / Remote

    private func configureRemoteCommands() {
        let c = MPRemoteCommandCenter.shared()
        c.playCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlayPause() }
            return .success
        }
        c.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlayPause() }
            return .success
        }
        c.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.next() }
            return .success
        }
        c.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.previous() }
            return .success
        }
        c.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let e = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            Task { @MainActor in self?.seek(to: e.positionTime) }
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let track = current else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: track.title,
            MPMediaItemPropertyArtist: track.artist,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        if let image = track.artworkImage ?? UIImage(systemName: "music.note") {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func updateNowPlayingTime() {
        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    var currentTimeText: String { Self.timeString(currentTime) }
    var remainingTimeText: String { "-" + Self.timeString(max(0, duration - currentTime)) }

    static func timeString(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
