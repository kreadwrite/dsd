//
//  MyMusicView.swift
//  Aura
//

import SwiftUI
import PhotosUI
import UIKit

struct MyMusicView: View {
    @EnvironmentObject private var library: LocalMusicLibrary
    @ObservedObject private var player = AudioPlayerManager.shared

    @State private var query = ""
    @State private var editingTrack: Track?
    @State private var deleteError: String?

    private var filteredTracks: [Track] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanQuery.isEmpty else { return library.tracks }
        return library.tracks.filter {
            $0.title.localizedCaseInsensitiveContains(cleanQuery)
            || $0.artist.localizedCaseInsensitiveContains(cleanQuery)
            || $0.genre.localizedCaseInsensitiveContains(cleanQuery)
            || ($0.detailText?.localizedCaseInsensitiveContains(cleanQuery) == true)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header
                searchField

                if filteredTracks.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredTracks) { track in
                            trackCard(track)
                        }
                    }
                    .padding(.horizontal, 20)
                }

                Color.clear.frame(height: 70)
            }
            .padding(.top, 10)
        }
        .scrollIndicators(.hidden)
        .background(AppBackground())
        .navigationTitle("Моя музыка")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingTrack) { track in
            EditLocalTrackSheet(track: track)
                .environmentObject(library)
        }
        .alert("Моя музыка", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK", role: .cancel) { deleteError = nil }
        } message: {
            Text(deleteError ?? "")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Локальная библиотека")
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(AuraColor.textPrimary)
            Text("Здесь можно запускать, редактировать и удалять треки, импортированные из Files.")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(AuraColor.textSecondary)
        }
        .padding(.horizontal, 20)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AuraColor.textSecondary)
            TextField("Поиск по названию, артисту или жанру", text: $query)
                .textInputAutocapitalization(.never)
                .foregroundStyle(AuraColor.textPrimary)
        }
        .padding(.horizontal, 16)
        .frame(height: 52)
        .auraGlass(in: .rect(cornerRadius: 18))
        .padding(.horizontal, 20)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "music.note.list")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(AuraColor.green)
            Text(query.isEmpty ? "Пока нет загруженных треков" : "Ничего не найдено")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AuraColor.textPrimary)
            Text(query.isEmpty ? "Добавь MP3 в профиле, и он появится здесь и в поиске." : "Попробуй другое название, артиста или жанр.")
                .font(.system(size: 14))
                .foregroundStyle(AuraColor.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .auraGlass(in: .rect(cornerRadius: 22))
        .padding(.horizontal, 20)
    }

    private func trackCard(_ track: Track) -> some View {
        HStack(spacing: 12) {
            CoverArt(
                imageURL: track.imageURL,
                initials: track.initials,
                colorSeed: track.colorSeed,
                artworkData: track.artworkData,
                cornerRadius: 16,
                showInitials: true
            )
            .frame(width: 62, height: 62)

            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(AuraColor.textPrimary)
                    .lineLimit(1)
                Text(track.artist)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(AuraColor.textSecondary)
                    .lineLimit(1)
                HStack(spacing: 8) {
                    Text(track.genre)
                    Text(track.durationText)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AuraColor.green)
            }

            Spacer(minLength: 8)

            Menu {
                Button {
                    player.playSingle(track)
                } label: {
                    Label("Слушать", systemImage: "play.fill")
                }
                Button {
                    editingTrack = track
                } label: {
                    Label("Изменить", systemImage: "pencil")
                }
                Button(role: .destructive) {
                    delete(track)
                } label: {
                    Label("Удалить", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AuraColor.textPrimary)
                    .frame(width: 42, height: 42)
                    .auraGlass(in: .circle, interactive: true)
            }
        }
        .padding(12)
        .auraGlass(in: .rect(cornerRadius: 20))
        .contentShape(.rect)
        .onTapGesture {
            player.playSingle(track)
        }
    }

    private func delete(_ track: Track) {
        do {
            try library.deleteTrack(id: track.id)
            HapticManager.success()
        } catch {
            deleteError = error.localizedDescription
        }
    }
}

private struct EditLocalTrackSheet: View {
    @EnvironmentObject private var library: LocalMusicLibrary
    @Environment(\.dismiss) private var dismiss

    let track: Track

    @State private var title: String
    @State private var artist: String
    @State private var genre: Genre
    @State private var notes: String
    @State private var coverItem: PhotosPickerItem?
    @State private var coverData: Data?
    @State private var errorMessage: String?

    init(track: Track) {
        self.track = track
        _title = State(initialValue: track.title)
        _artist = State(initialValue: track.artist)
        _genre = State(initialValue: Genre.resolve(track.genre) ?? .pop)
        _notes = State(initialValue: track.lyrics ?? track.detailText ?? "")
        _coverData = State(initialValue: track.artworkData)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Трек") {
                    TextField("Название", text: $title)
                    TextField("Исполнитель", text: $artist)
                    Picker("Жанр", selection: $genre) {
                        ForEach(Genre.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    TextField("Текст / заметка", text: $notes, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section("Обложка") {
                    PhotosPicker(selection: $coverItem, matching: .images) {
                        Label(coverData == nil ? "Выбрать обложку" : "Заменить обложку", systemImage: "photo")
                    }
                    if let coverData, let image = UIImage(data: coverData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 86, height: 86)
                            .clipShape(.rect(cornerRadius: 16))
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppBackground())
            .navigationTitle("Изменить трек")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Сохранить") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .alert("Изменить трек", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onChange(of: coverItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        coverData = data
                    }
                }
            }
        }
    }

    private func save() {
        do {
            try library.updateTrack(
                id: track.id,
                title: title,
                artist: artist,
                genre: genre,
                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes,
                artworkData: coverData
            )
            HapticManager.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
