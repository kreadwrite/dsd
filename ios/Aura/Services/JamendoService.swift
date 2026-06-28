//
//  JamendoService.swift
//  Aura
//
//  Lightweight Jamendo API client using only URLSession.
//  Falls back gracefully to the local catalogue on any failure.
//

import Foundation

nonisolated struct JamendoService {
    static let clientID = "10183d3f"
    private static let base = "https://api.jamendo.com/v3.0"

    // MARK: - Decoding

    private struct Response: Decodable {
        let results: [JTrack]
    }

    private struct JTrack: Decodable {
        let id: String
        let name: String
        let artist_name: String
        let duration: Int
        let audio: String
        let album_image: String?
        let musicinfo: MusicInfo?

        struct MusicInfo: Decodable {
            let tags: Tags?
            struct Tags: Decodable { let genres: [String]? }
        }
    }

    private static func map(_ j: JTrack) -> Track {
        let genre = j.musicinfo?.tags?.genres?.first?.capitalized ?? "Поп"
        let seed: UInt = (UInt(j.id) ?? 0) % 2 == 0 ? 0x1DB954 : 0x0A84FF
        let initials = String(j.artist_name.prefix(2)).uppercased()
        return Track(
            id: "jam_\(j.id)",
            title: j.name,
            artist: j.artist_name,
            genre: genre,
            duration: j.duration,
            streamURL: j.audio,
            imageURL: (j.album_image?.isEmpty == false) ? j.album_image : nil,
            initials: initials,
            colorSeed: seed
        )
    }

    // MARK: - Requests

    static func popular(limit: Int = 20) async -> [Track] {
        let urlString = "\(base)/tracks/?client_id=\(clientID)&format=json&limit=\(limit)&order=popularity_total&audioformat=mp31&include=musicinfo"
        return await fetch(urlString)
    }

    static func search(_ query: String, limit: Int = 25) async -> [Track] {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "\(base)/tracks/?client_id=\(clientID)&format=json&limit=\(limit)&namesearch=\(q)&audioformat=mp31&include=musicinfo"
        return await fetch(urlString)
    }

    static func byGenre(_ genre: String, limit: Int = 25) async -> [Track] {
        let q = genre.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? genre
        let urlString = "\(base)/tracks/?client_id=\(clientID)&format=json&limit=\(limit)&tags=\(q)&audioformat=mp31&include=musicinfo&order=popularity_total"
        return await fetch(urlString)
    }

    private static func fetch(_ urlString: String) async -> [Track] {
        guard let url = URL(string: urlString) else { return [] }
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 12
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }
            let decoded = try JSONDecoder().decode(Response.self, from: data)
            return decoded.results.filter { !$0.audio.isEmpty }.map(map)
        } catch {
            return []
        }
    }
}
