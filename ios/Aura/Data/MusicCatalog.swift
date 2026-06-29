//
//  MusicCatalog.swift
//  Aura
//
//  Hardcoded demo catalogue. All tracks reference royalty-free instrumental
//  samples so they play without any copyright concerns, while metadata uses
//  fictional titles attributed to well-known artists for demonstration.
//

import Foundation

nonisolated enum MusicCatalog {
    /// Royalty-free instrumental samples (SoundHelix) used as playable audio.
    private static let samples: [String] = (1...16).map {
        "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-\($0).mp3"
    }

    private static func sample(_ i: Int) -> String { samples[i % samples.count] }

    struct Seed {
        let artist: String
        let initials: String
        let genre: Genre
        let color: UInt
        let titles: [String]
    }

    private static let seeds: [Seed] = [
        Seed(artist: "MORGENSHTERN", initials: "MG", genre: .rap, color: 0x1DB954,
             titles: ["Неоновый дым", "Город не спит"]),
        Seed(artist: "Lil Peep", initials: "LP", genre: .indie, color: 0x1DB954,
             titles: ["Розовые облака", "Тихий шум"]),
        Seed(artist: "Miyagi & Andy Panda", initials: "MA", genre: .hipHop, color: 0x1ED760,
             titles: ["Горный ветер", "Свет внутри"]),
        Seed(artist: "PHARAOH", initials: "PH", genre: .rap, color: 0x1DB954,
             titles: ["Чёрный кашемир", "Дикий лес"]),
        Seed(artist: "ЛСП", initials: "ЛС", genre: .pop, color: 0x1DB954,
             titles: ["Стеклянный дом", "Танцы до утра"]),
        Seed(artist: "Макс Корж", initials: "МК", genre: .pop, color: 0x1ED760,
             titles: ["Малый повзрослел", "Своё небо"]),
        Seed(artist: "Скриптонит", initials: "СК", genre: .rnb, color: 0x1DB954,
             titles: ["Вечер в Алматы", "Дым и неон"]),
        Seed(artist: "Markul", initials: "MK", genre: .hipHop, color: 0x1ED760,
             titles: ["Над облаками", "Пустые улицы"]),
        Seed(artist: "Boulevard Depo", initials: "BD", genre: .rap, color: 0x1DB954,
             titles: ["Сапфир", "Холодный апрель"]),
        Seed(artist: "OG Buda", initials: "OB", genre: .hipHop, color: 0x1ED760,
             titles: ["Молодой адвокат", "Феррари мечты"]),
        Seed(artist: "Three Days Grace", initials: "TG", genre: .rock, color: 0x1DB954,
             titles: ["Animal Inside", "Breaking Silence"]),
        Seed(artist: "Mujuice", initials: "MJ", genre: .electronic, color: 0x1ED760,
             titles: ["Метро в полночь", "Электрический сон"]),
    ]

    static let allTracks: [Track] = {
        var result: [Track] = []
        var index = 0
        for seed in seeds {
            for title in seed.titles {
                let id = "tr_\(index)"
                result.append(
                    Track(
                        id: id,
                        title: title,
                        artist: seed.artist,
                        genre: seed.genre.rawValue,
                        duration: 150 + (index * 13) % 120,
                        streamURL: sample(index),
                        imageURL: nil,
                        isLocal: false,
                        detailText: nil,
                        artworkData: nil,
                        initials: seed.initials,
                        colorSeed: seed.color
                    )
                )
                index += 1
            }
        }
        return result
    }()

    static let artists: [Artist] = {
        seeds.enumerated().map { idx, seed in
            let ids = allTracks.filter { $0.artist == seed.artist }.map(\.id)
            return Artist(
                id: "ar_\(idx)",
                name: seed.artist,
                genre: seed.genre.rawValue,
                initials: seed.initials,
                colorSeed: seed.color,
                trackIDs: ids
            )
        }
    }()

    static let albums: [Album] = {
        seeds.enumerated().map { idx, seed in
            let ids = allTracks.filter { $0.artist == seed.artist }.map(\.id)
            return Album(
                id: "al_\(idx)",
                title: seed.titles.first ?? seed.artist,
                artist: seed.artist,
                initials: seed.initials,
                colorSeed: seed.color,
                trackIDs: ids
            )
        }
    }()

    static func track(id: String) -> Track? {
        allTracks.first { $0.id == id }
    }

    static func tracks(ids: [String]) -> [Track] {
        ids.compactMap { track(id: $0) }
    }

    // Curated home-screen rails.
    static var recommendations: [Track] { Array(allTracks.shuffled().prefix(8)) }
    static var recentlyPlayed: [Track] { Array(allTracks.prefix(8)) }
}
