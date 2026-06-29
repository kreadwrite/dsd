//
//  MusicProviderService.swift
//  Aura
//

import Foundation

enum MusicProviderID: String, CaseIterable, Codable {
    case local
    case catalog
    case jamendo
    case audius
    case soundCloud = "soundcloud"

    var title: String {
        switch self {
        case .local: return "Моя"
        case .catalog: return "Aura"
        case .jamendo: return "Jamendo"
        case .audius: return "Audius"
        case .soundCloud: return "SoundCloud"
        }
    }
}

struct MusicProviderConfig {
    static var supabaseFunctionsBaseURL: URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "AURA_SUPABASE_FUNCTIONS_URL") as? String,
              !raw.isEmpty else { return nil }
        return URL(string: raw)
    }
}

nonisolated struct MusicProviderService {
    private struct EdgeResponse: Decodable {
        let tracks: [EdgeTrack]
    }

    private struct EdgeTrack: Decodable {
        let id: String
        let title: String
        let artist: String
        let genre: String?
        let duration: Int?
        let streamURL: String
        let imageURL: String?
        let externalURL: String?
        let lyrics: String?
    }

    static func search(_ query: String, localTracks: [Track]) async -> [Track] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }

        async let jamendo = JamendoService.search(q)
        async let audius = edgeSearch(provider: .audius, query: q)
        async let soundCloud = edgeSearch(provider: .soundCloud, query: q)

        let local = (MusicCatalog.allTracks + localTracks).filter {
            $0.title.localizedCaseInsensitiveContains(q)
            || $0.artist.localizedCaseInsensitiveContains(q)
            || $0.genre.localizedCaseInsensitiveContains(q)
            || ($0.detailText?.localizedCaseInsensitiveContains(q) == true)
        }

        let jamendoTracks = await jamendo
        let audiusTracks = await audius
        let soundCloudTracks = await soundCloud
        return local + jamendoTracks + audiusTracks + soundCloudTracks
    }

    static func byGenre(_ genre: Genre, localTracks: [Track]) async -> [Track] {
        async let jamendo = JamendoService.byGenre(genre.rawValue.lowercased())
        let local = (MusicCatalog.allTracks + localTracks).filter { $0.genre == genre.rawValue }
        let jamendoTracks = await jamendo
        return local + jamendoTracks
    }

    private static func edgeSearch(provider: MusicProviderID, query: String) async -> [Track] {
        guard let base = MusicProviderConfig.supabaseFunctionsBaseURL else { return [] }
        var components = URLComponents(url: base.appendingPathComponent("music-search"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "provider", value: provider.rawValue),
            URLQueryItem(name: "q", value: query)
        ]
        guard let url = components?.url else { return [] }

        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 12
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return [] }
            let decoded = try JSONDecoder().decode(EdgeResponse.self, from: data)
            return decoded.tracks.map { map($0, provider: provider) }
        } catch {
            return []
        }
    }

    private static func map(_ item: EdgeTrack, provider: MusicProviderID) -> Track {
        Track(
            id: "\(provider.rawValue)_\(item.id)",
            source: provider.rawValue,
            sourceID: item.id,
            title: item.title,
            artist: item.artist,
            genre: item.genre ?? "Поп",
            duration: item.duration ?? 0,
            streamURL: item.streamURL,
            imageURL: item.imageURL,
            isLocal: false,
            detailText: nil,
            externalURL: item.externalURL,
            lyrics: item.lyrics,
            artworkData: nil,
            initials: String(item.artist.prefix(2)).uppercased(),
            colorSeed: 0x1DB954
        )
    }
}
