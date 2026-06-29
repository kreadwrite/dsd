//
//  AppSettings.swift
//  Aura
//
//  User preferences persisted with @AppStorage, exposed as an ObservableObject.
//

import SwiftUI
import Combine
import UIKit

enum ThemeChoice: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

/// Global, observable settings backed by UserDefaults via @AppStorage.
final class AppSettings: ObservableObject {
    @AppStorage("userName") var userName: String = "Слушатель"
    @AppStorage("hasOnboarded") var hasOnboarded: Bool = false
    @AppStorage("themeChoice") private var themeRaw: String = ThemeChoice.dark.rawValue
    @AppStorage("languageChoice") private var languageRaw: String = AppLanguage.ru.rawValue
    @AppStorage("notificationsEnabled") var notificationsEnabled: Bool = true
    /// Reminder time stored as minutes from midnight (default 10:00 = 600).
    @AppStorage("reminderMinutes") var reminderMinutes: Int = 600
    /// Total listening time accumulated, in seconds.
    @AppStorage("listeningSeconds") var listeningSeconds: Int = 0
    @AppStorage("preferredGenreRaw") private var preferredGenreRaw: String = ""
    @AppStorage("genreListeningData") private var genreListeningData: String = ""
    /// Stored avatar image as base64 (optional).
    @AppStorage("avatarData") private var avatarBase64: String = ""

    // Republish when @AppStorage changes (since these are computed wrappers).
    let objectWillChange = ObservableObjectPublisher()

    init() {
        migrateLegacyListeningDataIfNeeded()
    }

    var theme: ThemeChoice {
        get { ThemeChoice(rawValue: themeRaw) ?? .dark }
        set { objectWillChange.send(); themeRaw = newValue.rawValue }
    }

    var language: AppLanguage {
        get { AppLanguage(rawValue: languageRaw) ?? .ru }
        set { objectWillChange.send(); languageRaw = newValue.rawValue }
    }

    var avatarImage: UIImage? {
        get {
            guard let data = Data(base64Encoded: avatarBase64) else { return nil }
            return UIImage(data: data)
        }
        set {
            objectWillChange.send()
            if let data = newValue?.jpegData(compressionQuality: 0.8) {
                avatarBase64 = data.base64EncodedString()
            } else {
                avatarBase64 = ""
            }
        }
    }

    func t(_ key: LKey) -> String { L.t(key, language) }

    /// Auto-derived preferred genre once enough listening history exists.
    var preferredGenre: Genre? {
        get { Genre(rawValue: preferredGenreRaw) }
        set {
            objectWillChange.send()
            preferredGenreRaw = newValue?.rawValue ?? ""
        }
    }

    var preferredGenreTitle: String {
        preferredGenre?.rawValue ?? favoriteGenre
    }

    /// Favorite genre derived from the most common genre in the catalogue.
    var favoriteGenre: String {
        let counts = Dictionary(grouping: MusicCatalog.allTracks, by: \.genre)
            .mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key ?? "Поп"
    }

    var reminderDate: Date {
        get {
            Calendar.current.date(
                bySettingHour: reminderMinutes / 60,
                minute: reminderMinutes % 60,
                second: 0,
                of: Date()
            ) ?? Date()
        }
        set {
            let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            objectWillChange.send()
            reminderMinutes = (comps.hour ?? 10) * 60 + (comps.minute ?? 0)
        }
    }

    func registerListening(seconds: Int, genre: String?) {
        guard seconds > 0 else { return }
        objectWillChange.send()
        listeningSeconds += seconds

        if let genre, !genre.isEmpty {
            var counts = genreListeningSeconds
            counts[genre, default: 0] += seconds
            genreListeningSeconds = counts
            updatePreferredGenreIfNeeded()
        }
    }

    private var genreListeningSeconds: [String: Int] {
        get {
            guard let data = genreListeningData.data(using: .utf8),
                  let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else {
                return [:]
            }
            return decoded
        }
        set {
            objectWillChange.send()
            genreListeningData = (try? String(data: JSONEncoder().encode(newValue), encoding: .utf8)) ?? ""
        }
    }

    private func updatePreferredGenreIfNeeded() {
        guard listeningSeconds >= 600 else { return }
        guard let dominant = genreListeningSeconds.max(by: { $0.value < $1.value })?.key,
              let genre = Genre.resolve(dominant) else { return }
        preferredGenre = genre
    }

    private func migrateLegacyListeningDataIfNeeded() {
        guard listeningSeconds >= 4_000 * 60 else { return }
        listeningSeconds = 0
        preferredGenreRaw = ""
        genreListeningData = ""
    }
}
