//
//  Localization.swift
//  Aura
//
//  Lightweight in-app localisation (Russian / English) driven by user setting.
//

import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case ru
    case en

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ru: return "Русский"
        case .en: return "English"
        }
    }
}

/// String keys with Russian + English values.
enum LKey {
    case home, search, profile, favorites, library
    case goodMorning, goodAfternoon, goodEvening
    case recentlyPlayed, recommendations, popularAlbums, topArtists
    case searchPrompt, browseGenres, songs, artists, albums, noResults
    case nowPlaying, lyricsSoon, queue
    case settings, theme, themeLight, themeDark, themeSystem
    case notifications, notificationTime, language
    case listeningTime, favoriteGenre, preferredGenre, editName, name, save, cancel, done
    case onbStart, onbNext, onbSkip
    case onb1Title, onb1Body, onb2Title, onb2Body, onb3Title, onb3Body
    case defaultUser
    case minutesShort, tracksCount
    case likedTracks, emptyFavorites, emptyFavoritesBody
    case stats, account, dailyReminder, reminderOn
    case allGenres, myMusic, addMusic, trackNotes, cover, selectGenre
    case importMusic, titleField, artistField, genreField
}

struct L {
    static func t(_ key: LKey, _ lang: AppLanguage) -> String {
        switch key {
        case .home: return lang == .ru ? "Главная" : "Home"
        case .search: return lang == .ru ? "Поиск" : "Search"
        case .profile: return lang == .ru ? "Профиль" : "Profile"
        case .favorites: return lang == .ru ? "Избранное" : "Favorites"
        case .library: return lang == .ru ? "Библиотека" : "Library"
        case .goodMorning: return lang == .ru ? "Доброе утро" : "Good morning"
        case .goodAfternoon: return lang == .ru ? "Добрый день" : "Good afternoon"
        case .goodEvening: return lang == .ru ? "Добрый вечер" : "Good evening"
        case .recentlyPlayed: return lang == .ru ? "Недавно прослушанные" : "Recently played"
        case .recommendations: return lang == .ru ? "Рекомендации для вас" : "Made for you"
        case .popularAlbums: return lang == .ru ? "Популярные альбомы" : "Popular albums"
        case .topArtists: return lang == .ru ? "Лучшие исполнители" : "Top artists"
        case .searchPrompt: return lang == .ru ? "Что хотите послушать?" : "What do you want to listen to?"
        case .browseGenres: return lang == .ru ? "Жанры и настроения" : "Browse genres"
        case .songs: return lang == .ru ? "Треки" : "Songs"
        case .artists: return lang == .ru ? "Исполнители" : "Artists"
        case .albums: return lang == .ru ? "Альбомы" : "Albums"
        case .noResults: return lang == .ru ? "Ничего не найдено" : "No results"
        case .nowPlaying: return lang == .ru ? "Сейчас играет" : "Now playing"
        case .lyricsSoon: return lang == .ru ? "Текст скоро появится" : "Lyrics coming soon"
        case .queue: return lang == .ru ? "Очередь" : "Queue"
        case .settings: return lang == .ru ? "Настройки" : "Settings"
        case .theme: return lang == .ru ? "Тема" : "Theme"
        case .themeLight: return lang == .ru ? "Светлая" : "Light"
        case .themeDark: return lang == .ru ? "Тёмная" : "Dark"
        case .themeSystem: return lang == .ru ? "Системная" : "System"
        case .notifications: return lang == .ru ? "Уведомления" : "Notifications"
        case .notificationTime: return lang == .ru ? "Время напоминания" : "Reminder time"
        case .language: return lang == .ru ? "Язык" : "Language"
        case .listeningTime: return lang == .ru ? "Время прослушивания" : "Listening time"
        case .favoriteGenre: return lang == .ru ? "Любимый жанр" : "Favorite genre"
        case .preferredGenre: return lang == .ru ? "Предпочитаемый жанр" : "Preferred genre"
        case .editName: return lang == .ru ? "Изменить имя" : "Edit name"
        case .name: return lang == .ru ? "Имя" : "Name"
        case .save: return lang == .ru ? "Сохранить" : "Save"
        case .cancel: return lang == .ru ? "Отмена" : "Cancel"
        case .done: return lang == .ru ? "Готово" : "Done"
        case .onbStart: return lang == .ru ? "Начать" : "Get started"
        case .onbNext: return lang == .ru ? "Далее" : "Next"
        case .onbSkip: return lang == .ru ? "Пропустить" : "Skip"
        case .onb1Title: return lang == .ru ? "Твой звук" : "Your sound"
        case .onb1Body: return lang == .ru ? "Миллионы треков любимых артистов всегда под рукой — без лишнего." : "Millions of tracks from your favourite artists, always at hand."
        case .onb2Title: return lang == .ru ? "Идеальные подборки" : "Perfect picks"
        case .onb2Body: return lang == .ru ? "Рекомендации, которые понимают твоё настроение и подстраиваются под тебя." : "Recommendations that understand your mood and adapt to you."
        case .onb3Title: return lang == .ru ? "Стекло и свет" : "Glass & light"
        case .onb3Body: return lang == .ru ? "Плавный интерфейс на жидком стекле. Просто наслаждайся музыкой." : "A fluid liquid-glass interface. Just enjoy the music."
        case .defaultUser: return lang == .ru ? "Слушатель" : "Listener"
        case .minutesShort: return lang == .ru ? "мин" : "min"
        case .tracksCount: return lang == .ru ? "треков" : "tracks"
        case .likedTracks: return lang == .ru ? "Любимые треки" : "Liked songs"
        case .emptyFavorites: return lang == .ru ? "Пока пусто" : "Nothing yet"
        case .emptyFavoritesBody: return lang == .ru ? "Нажми на сердечко у трека, чтобы добавить его сюда." : "Tap the heart on a track to add it here."
        case .stats: return lang == .ru ? "Статистика" : "Stats"
        case .account: return lang == .ru ? "Аккаунт" : "Account"
        case .dailyReminder: return lang == .ru ? "Ежедневное напоминание" : "Daily reminder"
        case .reminderOn: return lang == .ru ? "Напоминать слушать музыку" : "Remind me to listen"
        case .allGenres: return lang == .ru ? "Все" : "All"
        case .myMusic: return lang == .ru ? "Моя музыка" : "My music"
        case .addMusic: return lang == .ru ? "Добавить музыку" : "Add music"
        case .trackNotes: return lang == .ru ? "Текст / заметка" : "Text / note"
        case .cover: return lang == .ru ? "Обложка" : "Cover"
        case .selectGenre: return lang == .ru ? "Выбрать жанр" : "Select genre"
        case .importMusic: return lang == .ru ? "Импорт MP3" : "Import MP3"
        case .titleField: return lang == .ru ? "Название" : "Title"
        case .artistField: return lang == .ru ? "Исполнитель" : "Artist"
        case .genreField: return lang == .ru ? "Жанр" : "Genre"
        }
    }
}
