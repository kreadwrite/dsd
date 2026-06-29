//
//  SocialStore.swift
//  Aura
//

import Foundation
import Combine

struct TrackComment: Identifiable, Codable, Hashable {
    let id: String
    let trackID: String
    let userName: String
    let parentID: String?
    var text: String
    let createdAt: Date
    var likeCount: Int
}

@MainActor
final class SocialStore: ObservableObject {
    static let shared = SocialStore()

    @Published private(set) var commentsByTrack: [String: [TrackComment]] = [:]

    private let commentsKey = "aura.comments.v1"

    private init() {
        load()
    }

    func comments(for trackID: String) -> [TrackComment] {
        commentsByTrack[trackID, default: []].sorted { $0.createdAt < $1.createdAt }
    }

    func addComment(trackID: String, userName: String, text: String, parentID: String?) {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        let comment = TrackComment(
            id: UUID().uuidString,
            trackID: trackID,
            userName: userName.isEmpty ? "Listener" : userName,
            parentID: parentID,
            text: cleaned,
            createdAt: Date(),
            likeCount: 0
        )
        commentsByTrack[trackID, default: []].append(comment)
        save()
    }

    func likeComment(_ comment: TrackComment) {
        guard var comments = commentsByTrack[comment.trackID],
              let index = comments.firstIndex(where: { $0.id == comment.id }) else { return }
        comments[index].likeCount += 1
        commentsByTrack[comment.trackID] = comments
        save()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: commentsKey),
              let decoded = try? JSONDecoder().decode([String: [TrackComment]].self, from: data) else { return }
        commentsByTrack = decoded
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(commentsByTrack) else { return }
        UserDefaults.standard.set(data, forKey: commentsKey)
    }
}
