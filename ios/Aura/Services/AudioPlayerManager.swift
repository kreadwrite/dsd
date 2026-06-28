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
    @Published var progress: Double = 0          // 0...1
    @Published var currentTime: Double = 0        // seconds
    @Published var duration: Double = 0           // seconds
    @Published var volume: Double = 0.8
    @Published var isShuffle = false
    @Published var repeatMode: RepeatMode = .off
    @Published private(set) var favorites: Set<String> = []

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var queue: [Track] = []
    private var index = 0
    private var settings: AppSettings?
    private let favoritesKey = "favoriteTrackIDs"

    private init() {
        configureSession()
        configureRemoteCommands()
        loadFavorites()
    }

    func attach(settings: AppSettings) {
        self.settings = settings
    }

    // MARK: - Session

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error.localizedDescription)")
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
        let track = queue[index]
        current = track
        duration = Double(track.duration)

        guard let url = URL(string: track.streamURL) else { return }
        if let observer = timeObserver { player?.removeTimeObserver(observer); timeObserver = nil }

        let item = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: item)
        player?.volume = Float(volume)

        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(itemDidFinish),
            name: .AVPlayerItemDidPlayToEndTime, object: item
        )

        addTimeObserver()
        player?.play()
        isPlaying = true
        updateNowPlaying()
        HapticManager.tap()
    }

    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.4, preferredTimescale: 600)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            Task { @MainActor in
                self.currentTime = time.seconds
                if let dur = self.player?.currentItem?.duration.seconds, dur.isFinite, dur > 0 {
                    self.duration = dur
                    self.progress = self.currentTime / dur
                }
                self.updateNowPlayingTime()
            }
        }
    }

    @objc private func itemDidFinish() {
        Task { @MainActor in
            self.settings?.addListening(seconds: Int(self.duration))
            switch self.repeatMode {
            case .one: self.seek(to: 0); self.player?.play()
            default: self.next()
            }
        }
    }

    // MARK: - Transport

    func togglePlayPause() {
        guard player != nil else {
            if let track = current { playSingle(track) }
            return
        }
        if isPlaying { player?.pause() } else { player?.play() }
        isPlaying.toggle()
        updateNowPlaying()
        HapticManager.tap()
    }

    func next() {
        guard !queue.isEmpty else { return }
        if isShuffle {
            index = Int.random(in: 0..<queue.count)
        } else if index + 1 < queue.count {
            index += 1
        } else if repeatMode == .all {
            index = 0
        } else {
            player?.pause(); isPlaying = false; return
        }
        startCurrent()
    }

    func previous() {
        guard !queue.isEmpty else { return }
        if currentTime > 3 {
            seek(to: 0); return
        }
        index = index > 0 ? index - 1 : queue.count - 1
        startCurrent()
    }

    func seek(to seconds: Double) {
        player?.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
        currentTime = seconds
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
            MusicCatalog.track(id: id) ?? (current?.id == id ? current : nil)
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
            Task { @MainActor in self?.togglePlayPause() }; return .success
        }
        c.pauseCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.togglePlayPause() }; return .success
        }
        c.nextTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.next() }; return .success
        }
        c.previousTrackCommand.addTarget { [weak self] _ in
            Task { @MainActor in self?.previous() }; return .success
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
        if let img = UIImage(systemName: "music.note") {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: img.size) { _ in img }
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
