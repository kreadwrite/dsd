//
//  AppSettings.swift
//  Aura
//
//  User preferences persisted with @AppStorage, exposed as an ObservableObject.
//

import SwiftUI
import Combine

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
    @AppStorage("listeningSeconds") var listeningSeconds: Int = 4_530 * 60
    /// Stored avatar image as base64 (optional).
    @AppStorage("avatarData") private var avatarBase64: String = ""

    // Republish when @AppStorage changes (since these are computed wrappers).
    let objectWillChange = ObservableObjectPublisher()

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

    func addListening(seconds: Int) {
        listeningSeconds += seconds
    }
}
