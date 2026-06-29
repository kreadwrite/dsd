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
    @State private var showingFileImporter = false
    @State private var pendingImport: LocalMusicLibrary.PendingImport?
    @State private var importError: String?
    @State private var editingName = false
    @State private var draftName = ""

    private var listeningText: String {
        let minutes = settings.listeningSeconds / 60
        return "\(minutes) \(settings.t(.minutesShort))"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                profileHeader
                statsRow
                librarySection
                settingsCard
                Color.clear.frame(height: 70)
            }
            .padding(.top, 10)
        }
        .scrollIndicators(.hidden)
        .background(AppBackground())
        .navigationTitle(settings.t(.profile))
        .navigationBarTitleDisplayMode(.inline)
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
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.audio],
            allowsMultipleSelection: false
        ) { result in
            handleImportSelection(result)
        }
        .sheet(item: $pendingImport) { draft in
            AddMusicSheet(
                draft: draft,
                onSave: { title, artist, genre, notes, artworkData in
                    let imported = try await library.importPreparedTrack(
                        draft,
                        title: title,
                        artist: artist,
                        genre: genre,
                        notes: notes,
                        artworkData: artworkData
                    )
                    await MainActor.run {
                        player.playSingle(imported)
                    }
                    return imported
                }
            )
        }
        .alert(settings.t(.addMusic), isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button(settings.t(.done), role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "")
        }
        .alert(settings.t(.editName), isPresented: $editingName) {
            TextField(settings.t(.name), text: $draftName)
            Button(settings.t(.cancel), role: .cancel) {}
            Button(settings.t(.save)) {
                let trimmed = draftName.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty { settings.userName = trimmed }
            }
        }
    }

    private var profileHeader: some View {
        VStack(spacing: 14) {
            HStack {
                Text(settings.t(.library))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AuraColor.textSecondary)
                Spacer()
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(AuraColor.green)
            }
            .padding(.horizontal, 20)

            PhotosPicker(selection: $photoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let avatar = settings.avatarImage {
                            Image(uiImage: avatar).resizable().scaledToFill()
                        } else {
                            ZStack {
                                LinearGradient(colors: [AuraColor.green, AuraColor.greenBright],
                                               startPoint: .topLeading, endPoint: .bottomTrailing)
                                Text(String(settings.userName.prefix(1)).uppercased())
                                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(.white.opacity(0.15), lineWidth: 1))

                    Image(systemName: "camera.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.black)
                        .padding(9)
                        .background(Circle().fill(AuraColor.green))
                        .overlay(Circle().stroke(AuraColor.background, lineWidth: 3))
                }
            }
            .shadow(color: AuraColor.green.opacity(0.3), radius: 16, y: 8)

            Button {
                draftName = settings.userName
                editingName = true
            } label: {
                HStack(spacing: 6) {
                    Text(settings.userName)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(AuraColor.textPrimary)
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundStyle(AuraColor.green)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 14) {
            statCard(value: listeningText, label: settings.t(.listeningTime), symbol: "clock.fill", tint: AuraColor.green)
            statCard(value: settings.preferredGenreTitle, label: settings.t(.favoriteGenre), symbol: "music.note", tint: AuraColor.greenBright)
        }
        .padding(.horizontal, 20)
    }

    private func statCard(value: String, label: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(tint)
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

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: settings.t(.library))

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                Button {
                    showingFileImporter = true
                } label: {
                    libraryTile(
                        title: settings.t(.addMusic),
                        subtitle: "\(library.tracks.count) \(settings.t(.tracksCount))",
                        icon: "plus",
                        tint: AuraColor.green
                    )
                }
                .buttonStyle(.plain)

                libraryTile(
                    title: settings.t(.myMusic),
                    subtitle: "\(library.tracks.count) \(settings.t(.tracksCount))",
                    icon: "music.note.list",
                    tint: AuraColor.greenBright
                )
            }
            .padding(.horizontal, 20)
        }
    }

    private func libraryTile(title: String, subtitle: String, icon: String, tint: Color) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(colors: [tint.opacity(0.95), tint.opacity(0.55)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                Text(title)
                    .font(.system(size: 20, weight: .heavy))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.82))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            .padding(14)
        }
        .frame(height: 132)
        .clipShape(.rect(cornerRadius: 18))
        .shadow(color: tint.opacity(0.25), radius: 14, y: 6)
    }

    private var settingsCard: some View {
        VStack(spacing: 0) {
            settingsHeader
            divider
            settingsRow(symbol: "circle.lefthalf.filled", title: settings.t(.theme), tint: AuraColor.green) {
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
            settingsRow(symbol: "bell.fill", title: settings.t(.reminderOn), tint: AuraColor.green) {
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
            settingsRow(symbol: "clock.fill", title: settings.t(.notificationTime), tint: AuraColor.greenBright) {
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
            settingsRow(symbol: "globe", title: settings.t(.language), tint: AuraColor.green) {
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
            divider
            NavigationLink {
                FavoritesView()
            } label: {
                settingsRow(symbol: "heart.fill", title: settings.t(.favorites), tint: AuraColor.greenBright) {
                    Text("\(player.favoriteTracks.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AuraColor.textSecondary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .auraGlass(in: .rect(cornerRadius: 20))
        .padding(.horizontal, 20)
    }

    private var settingsHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AuraColor.green)
            Text(settings.t(.settings))
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(AuraColor.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func settingsRow<Trailing: View>(symbol: String, title: String, tint: Color, @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack(spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 28, height: 28)
                .background(Circle().fill(tint.opacity(0.15)))
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

    private func handleImportSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            Task {
                do {
                    pendingImport = try await library.prepareImport(from: url)
                } catch {
                    importError = error.localizedDescription
                }
            }
        case .failure(let error):
            importError = error.localizedDescription
        }
    }
}

private struct AddMusicSheet: View {
    let draft: LocalMusicLibrary.PendingImport
    let onSave: @Sendable (String, String, Genre, String?, Data?) async throws -> Track

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var settings: AppSettings

    @State private var title: String
    @State private var artist: String
    @State private var genre: Genre
    @State private var notes: String = ""
    @State private var artworkItem: PhotosPickerItem?
    @State private var artworkData: Data?
    @State private var saving = false
    @State private var errorMessage: String?

    init(
        draft: LocalMusicLibrary.PendingImport,
        onSave: @escaping @Sendable (String, String, Genre, String?, Data?) async throws -> Track
    ) {
        self.draft = draft
        self.onSave = onSave
        _title = State(initialValue: draft.suggestedTitle)
        _artist = State(initialValue: draft.suggestedArtist)
        _genre = State(initialValue: .rap)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    TextField(settings.t(.titleField), text: $title)
                        .textInputAutocapitalization(.words)
                        .padding()
                        .auraGlass(in: .rect(cornerRadius: 18))

                    TextField(settings.t(.artistField), text: $artist)
                        .textInputAutocapitalization(.words)
                        .padding()
                        .auraGlass(in: .rect(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 10) {
                        Text(settings.t(.genreField))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AuraColor.textPrimary)
                        Picker("", selection: $genre) {
                            ForEach(Genre.allCases) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(AuraColor.green)
                    }
                    .padding()
                    .auraGlass(in: .rect(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 10) {
                        Text(settings.t(.trackNotes))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(AuraColor.textPrimary)
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                            .padding(8)
                            .background(Color.clear)
                    }
                    .padding()
                    .auraGlass(in: .rect(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "photo")
                                .foregroundStyle(AuraColor.green)
                            Text(settings.t(.cover))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AuraColor.textPrimary)
                            Spacer()
                            PhotosPicker(selection: $artworkItem, matching: .images) {
                                Text(settings.t(.addMusic))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(AuraColor.green)
                            }
                        }

                        if let artworkData, let image = UIImage(data: artworkData) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 180)
                                .clipShape(.rect(cornerRadius: 16))
                        } else {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AuraColor.surface)
                                .frame(height: 140)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo.on.rectangle.angled")
                                            .font(.system(size: 24, weight: .semibold))
                                            .foregroundStyle(AuraColor.textSecondary)
                                        Text(settings.t(.coverHint))
                                            .font(.system(size: 13))
                                            .foregroundStyle(AuraColor.textSecondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .padding(.horizontal, 20)
                                )
                        }
                    }
                    .padding()
                    .auraGlass(in: .rect(cornerRadius: 18))

                    Text("\(draft.suggestedTitle) • \(draft.durationText)")
                        .font(.system(size: 13))
                        .foregroundStyle(AuraColor.textSecondary)
                }
                .padding(20)
            }
            .scrollIndicators(.hidden)
            .background(AppBackground())
            .navigationTitle(settings.t(.addMusic))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(settings.t(.cancel)) { dismiss() }
                        .foregroundStyle(AuraColor.green)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(settings.t(.save)) {
                        Task { await save() }
                    }
                    .foregroundStyle(AuraColor.green)
                    .disabled(saving)
                }
            }
            .alert(settings.t(.addMusic), isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button(settings.t(.done), role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .onChange(of: artworkItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        artworkData = data
                    }
                }
            }
        }
    }

    private func save() async {
        guard !saving else { return }
        saving = true
        defer { saving = false }
        do {
            _ = try await onSave(title.trimmingCharacters(in: .whitespacesAndNewlines),
                                 artist.trimmingCharacters(in: .whitespacesAndNewlines),
                                 genre,
                                 notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : notes,
                                 artworkData)
            HapticManager.success()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
