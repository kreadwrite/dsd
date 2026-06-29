//
//  CoverArt.swift
//  Aura
//
//  Album / artist cover. Uses a remote image when available, otherwise a
//  solid-colour placeholder with the artist initials (palette-only colours).
//

import SwiftUI
import UIKit

struct CoverArt: View {
    let imageURL: String?
    let initials: String
    let colorSeed: UInt
    var artworkData: Data? = nil
    var cornerRadius: CGFloat = 12
    var symbol: String = "music.note"
    var showInitials: Bool = true

    private var seedColor: Color { Color(hex: colorSeed) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [seedColor.opacity(0.85), seedColor.opacity(0.35), .black.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            if let artworkData, let uiImage = UIImage(data: artworkData) {
                Image(uiImage: uiImage).resizable().scaledToFill()
            } else if let urlString = imageURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        placeholderContent
                    }
                }
            } else {
                placeholderContent
            }
        }
        .clipShape(.rect(cornerRadius: cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(.white.opacity(0.08), lineWidth: 0.5)
        )
    }

    @ViewBuilder private var placeholderContent: some View {
        ZStack {
            Image(systemName: symbol)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(.white.opacity(0.25))
            if showInitials {
                Text(initials)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.9))
            }
        }
    }
}
