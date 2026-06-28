//
//  SearchView.swift
//  Aura
//

import SwiftUI
import Combine

@MainActor
final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [Track] = []
    @Published var isSearching = false
    @Published var selectedGenre: Genre?

    private var task: Task<Void, Never>?

    func runSearch() {
        task?.cancel()
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else {
            results = []
            isSearching = false
            return
        }
        isSearching = true
        task = Task {
            try? await Task.sleep(for: .milliseconds(350))
            if Task.isCancelled { return }
            let remote = await JamendoService.search(q)
            if Task.isCancelled { return }
            let local = MusicCatalog.allTracks.filter {
                $0.title.localizedCaseInsensitiveContains(q) || $0.artist.localizedCaseInsensitiveContains(q)
            }
            results = local + remote
            isSearching = false
        }
    }

    func loadGenre(_ genre: Genre) {
        selectedGenre = genre
        isSearching = true
        task?.cancel()
        task = Task {
            let remote = await JamendoService.byGenre(genre.rawValue.lowercased())
            if Task.isCancelled { return }
            let local = MusicCatalog.allTracks.filter { $0.genre == genre.rawValue }
            results = local + remote
            isSearching = false
        }
    }
}

struct SearchView: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject private var player = AudioPlayerManager.shared
    @StateObject private var vm = SearchViewModel()
    @FocusState private var focused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                // Search field
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AuraColor.textSecondary)
                    TextField(settings.t(.searchPrompt), text: $vm.query)
                        .focused($focused)
                        .foregroundStyle(AuraColor.textPrimary)
                        .submitLabel(.search)
                        .onChange(of: vm.query) { _, _ in vm.runSearch() }
                        .tint(AuraColor.green)
                    if !vm.query.isEmpty {
                        Button {
                            vm.query = ""; vm.results = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(AuraColor.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .auraGlass(in: .capsule, interactive: true)
                .padding(.horizontal, 20)
                .padding(.top, 8)

                if vm.results.isEmpty && !vm.isSearching {
                    genreSection
                }

                if vm.isSearching {
                    HStack { Spacer(); ProgressView().tint(AuraColor.green); Spacer() }
                        .padding(.top, 40)
                }

                if !vm.results.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionHeader(title: settings.t(.songs))
                        LazyVStack(spacing: 2) {
                            ForEach(vm.results) { track in
                                Button {
                                    player.play(track: track, in: vm.results)
                                } label: { TrackRow(track: track) }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }

                Color.clear.frame(height: 150)
            }
        }
        .scrollIndicators(.hidden)
        .background(AppBackground())
        .navigationTitle(settings.t(.search))
        .navigationBarTitleDisplayMode(.large)
    }

    private var genreSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: settings.t(.browseGenres))
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                ForEach(Genre.allCases) { genre in
                    Button {
                        HapticManager.tap()
                        vm.loadGenre(genre)
                    } label: {
                        genreTile(genre)
                    }
                    .buttonStyle(PressableStyle())
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func genreTile(_ genre: Genre) -> some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [genre.tint.opacity(0.9), genre.tint.opacity(0.4)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Image(systemName: genre.symbol)
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(.white.opacity(0.25))
                .rotationEffect(.degrees(20))
                .offset(x: 70, y: 10)
            Text(genre.rawValue)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .padding(14)
        }
        .frame(height: 96)
        .clipShape(.rect(cornerRadius: 16))
    }
}
