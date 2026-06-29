//
//  ProfileView.swift
//  Aura
//

import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var library: LocalMusicLibrary
    @ObservedObject private var player = AudioPlayerManager.shared

    @State private var photoItem: PhotosPickerItem?
    @State private var editingName = false
    @State private var draftName = ""
    @State private var showMusicImporter = false
    @State private var pendingImportURL: URL?
    @State private var showAddMusicSheet = false

    private var listeningText: String {
        let minutes = settings.listeningSeconds / 60
        return "\(minutes) \(settings.t(.minutesShort))"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                topHeader
                statsRow
                libraryCards
                SectionHeader(title: settings.t(.settings))
                settingsCard
                Color.clear.frame(height: 140)
            }
            .padding(.top, 6)
        }
        .scrollIndicators(.hidden)
        .background(AppBackground())
        .navigationTitle(settings.t(.profile))
        .navigationBarTitleDisplayMode(.inline)
        .fileImporter(
            isPresented: $showMusicImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                pendingImportURL = urls.first
                if pendingImportURL != nil {
                    showAddMusicSheet = true
                }
            case .failure:
                break
            }
        }
        .sheet(isPresented: $showAddMusicSheet) {
            if let pendingImportURL {
                AddMusicSheet(fileURL: pendingImportURL) { title, artist, genre, notes, coverData in
                    _ = try await library.importTrack(
                        from: pendingImportURL,
                        title: title,
                        artist: artist,
                        genre: genre,
                        notes: notes,
                        artworkData: coverData
                    )
                }
            }
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    settings.avatarImage = image
                    HapticManager.success()
                }
            }
        }
        .alert(settings.t(.editName), isPresented: $editingName) {
            TextField(settings.t(.name), text: $draftName)
            Button(settings.t(.cancel), role: .cancel) {}
            Button(settings.t(.save)) {
                let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { settings.userName = trimmed }
            }
        }
    }

    private var topHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AuraColor.green)
                    .frame(width: 38, height: 38)
                    .auraGlass(in: .circle, interactive: true)
                Spacer()
                PhotosPicker(selection: $photoItem, matching: .images) {
                    if let avatar = settings.avatarImage {
                        Image(uiImage: avatar)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(LinearGradient(colors: [AuraColor.green, AuraColor.greenBright], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .overlay(
                                Text(String(settings.userName.prefix(1)).uppercased())
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                            )
                            .frame(width: 40, height: 40)
                    }
                }
            }

            Button {
                draftName = settings.userName
                editingName = true
            } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Text(settings.t(.library))
                        .font(.system(size: 34, weight: .heavy, design: .rounded))
                        .foregroundStyle(AuraColor.textPrimary)
                    Text(settings.userName)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(AuraColor.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    private var statsRow: some View {
        HStack(spacing: 14) {
            statCard(value: listeningText, label: settings.t(.listeningTime), symbol: "clock.fill")
            statCard(value: settings.preferredGenreTitle, label: settings.t(.preferredGenre), symbol: "music.note")
        }
        .padding(.horizontal, 20)
    }

    private func statCard(value: String, label: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(AuraColor.green)
            Text(value)
                .font(.system(size: 20, weight: .heavy))
                .foregroundStyle(AuraColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(AuraColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .auraGlass(in: .rect(cornerRadius: 18))
    }

    private var libraryCards: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: settings.t(.myMusic))
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                Button {
                    showMusicImporter = true
                } label: {
                    libraryTile(
                        title: settings.t(.addMusic),
                        subtitle: "\(library.tracks.count) \(settings.t(.tracksCount))",
                        symbol: "plus.circle.fill",
                        gradient: [AuraColor.green, AuraColor.greenBright]
                    )
                }
                .buttonStyle(.plain)

                NavigationLink(destination: FavoritesView()) {
                    libraryTile(
                        title: settings.t(.favorites),
                        subtitle: "\(player.favoriteTracks.count) \(settings.t(.tracksCount))",
                        symbol: "heart.fill",
                        gradient: [AuraColor.greenBright, AuraColor.green]
                    )
                }
                .buttonStyle(.plain)

                libraryTile(
                    title: settings.t(.theme),
                    subtitle: themeSubtitle,
                    symbol: "circle.lefthalf.filled",
                    gradient: [AuraColor.green, AuraColor.green.opacity(0.75)]
                )

                libraryTile(
                    title: settings.t(.language),
                    subtitle: settings.language.displayName,
                    symbol: "globe",
                    gradient: [AuraColor.greenBright, AuraColor.green.opacity(0.75)]
                )
            }
            .padding(.horizontal, 20)
        }
    }

    private var themeSubtitle: String {
        switch settings.theme {
        case .system: return settings.t(.themeSystem)
        case .light: return settings.t(.themeLight)
        case .dark: return settings.t(.themeDark)
        }
    }

    private func libraryTile(title: String, subtitle: String, symbol: String, gradient: [Color]) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white.opacity(0.18))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(14)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .heavy))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .padding(14)
        }
        .frame(height: 128)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: gradient.first?.opacity(0.3) ?? .clear, radius: 16, y: 8)
    }

    private var settingsCard: some View {
        VStack(spacing: 0) {
            settingsRow(symbol: "circle.lefthalf.filled", title: settings.t(.theme)) {
                Picker("", selection: Binding(
                    get: { settings.theme },
                    set: { settings.theme = $0; HapticManager.selection() }
                )) {
                    Text(settings.t(.themeSystem)).tag(ThemeChoice.system)
                    Text(settings.t(.themeLight)).tag(ThemeChoice.light)
                    Text(settings.t(.themeDark)).tag(ThemeChoice.dark)
                }
                .pickerStyle(.menu)
                .tint(AuraColor.green)
            }
            divider
            settingsRow(symbol: "bell.fill", title: settings.t(.reminderOn)) {
                Toggle("", isOn: Binding(
                    get: { settings.notificationsEnabled },
                    set: { newValue in
                        settings.notificationsEnabled = newValue
                        NotificationManager.scheduleDaily(minutes: settings.reminderMinutes, enabled: newValue)
                    }
                ))
                .labelsHidden()
                .tint(AuraColor.green)
            }
            divider
            settingsRow(symbol: "clock.fill", title: settings.t(.notificationTime)) {
                DatePicker("", selection: Binding(
                    get: { settings.reminderDate },
                    set: { newValue in
                        settings.reminderDate = newValue
                        NotificationManager.scheduleDaily(minutes: settings.reminderMinutes, enabled: settings.notificationsEnabled)
                    }
                ), displayedComponents: .hourAndMinute)
                .labelsHidden()
                .tint(AuraColor.green)
            }
            divider
            settingsRow(symbol: "music.note", title: settings.t(.preferredGenre)) {
                Picker("", selection: Binding(
                    get: { settings.preferredGenre ?? .pop },
                    set: { settings.setPreferredGenre($0); HapticManager.selection() }
                )) {
                    ForEach(Genre.allCases) { genre in
                        Text(genre.rawValue).tag(genre)
                    }
                }
                .pickerStyle(.menu)
                .tint(AuraColor.green)
            }
            divider
            settingsRow(symbol: "globe", title: settings.t(.language)) {
                Picker("", selection: Binding(
                    get: { settings.language },
                    set: { settings.language = $0; HapticManager.selection() }
                )) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.menu)
                .tint(AuraColor.green)
            }
        }
        .padding(.vertical, 4)
        .auraGlass(in: .rect(cornerRadius: 20))
        .padding(.horizontal, 20)
    }

    private func settingsRow<Trailing: View>(symbol: String, title: String, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AuraColor.green)
                .frame(width: 28, height: 28)
                .background(Circle().fill(AuraColor.green.opacity(0.15)))
            Text(title)
                .font(.system(size: 16))
                .foregroundStyle(AuraColor.textPrimary)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var divider: some View {
        Rectangle().fill(AuraColor.hairline).frame(height: 0.5).padding(.leading, 58)
    }
}

private struct AddMusicSheet: View {
    let fileURL: URL
    let onSave: (String, String, Genre, String?, Data?) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var artist = ""
    @State private var notes = ""
    @State private var genre: Genre = .pop
    @State private var coverItem: PhotosPickerItem?
    @State private var coverData: Data?
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(fileURL.lastPathComponent)
                        .foregroundStyle(AuraColor.textSecondary)
                }
                Section {
                    TextField("Название", text: $title)
                    TextField("Исполнитель", text: $artist)
                    Picker("Жанр", selection: $genre) {
                        ForEach(Genre.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                    .tint(AuraColor.green)
                    TextField("Текст / заметка", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                Section {
                    PhotosPicker(selection: $coverItem, matching: .images) {
                        Label("Обложка", systemImage: "photo")
                    }
                    if coverData != nil {
                        Text("Обложка выбрана")
                            .foregroundStyle(AuraColor.textSecondary)
                    }
                }
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Импорт MP3")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "..." : "Добавить") {
                        Task { await save() }
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || artist.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)
                }
            }
            .onChange(of: coverItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    coverData = try? await newItem.loadTransferable(type: Data.self)
                }
            }
        }
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        do {
            try await onSave(
                title.trimmingCharacters(in: .whitespacesAndNewlines),
                artist.trimmingCharacters(in: .whitespacesAndNewlines),
                genre,
                notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes,
                coverData
            )
            HapticManager.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
