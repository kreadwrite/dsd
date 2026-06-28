//
//  ProfileView.swift
//  Aura
//

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject private var player = AudioPlayerManager.shared

    @State private var photoItem: PhotosPickerItem?
    @State private var editingName = false
    @State private var draftName = ""

    private var listeningText: String {
        let minutes = settings.listeningSeconds / 60
        return "\(minutes) \(settings.t(.minutesShort))"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                profileHeader

                statsRow

                settingsCard

                Color.clear.frame(height: 150)
            }
            .padding(.top, 8)
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
            PhotosPicker(selection: $photoItem, matching: .images) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let avatar = settings.avatarImage {
                            Image(uiImage: avatar).resizable().scaledToFill()
                        } else {
                            ZStack {
                                LinearGradient(colors: [AuraColor.green, AuraColor.blue],
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
                        .foregroundStyle(AuraColor.blue)
                }
            }
            .buttonStyle(.plain)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 14) {
            statCard(value: listeningText, label: settings.t(.listeningTime), symbol: "clock.fill", tint: AuraColor.green)
            statCard(value: settings.favoriteGenre, label: settings.t(.favoriteGenre), symbol: "music.note", tint: AuraColor.blue)
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
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(AuraColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .auraGlass(in: .rect(cornerRadius: 18))
    }

    private var settingsCard: some View {
        VStack(spacing: 0) {
            // Theme
            settingsRow(symbol: "circle.lefthalf.filled", title: settings.t(.theme), tint: AuraColor.blue) {
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
            // Notifications toggle
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
            // Reminder time
            settingsRow(symbol: "clock.fill", title: settings.t(.notificationTime), tint: AuraColor.blue) {
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
            // Language
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
        }
        .padding(.vertical, 4)
        .auraGlass(in: .rect(cornerRadius: 20))
        .padding(.horizontal, 20)
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
}
