//
//  Theme.swift
//  Aura
//
//  Centralised colour palette and glass helpers.
//  Strict palette: BLACK, WHITE, GRAY, GREEN, BLUE.
//

import SwiftUI

extension Color {
    /// Hex initialiser, e.g. Color(hex: 0x1DB954).
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}

/// The complete Aura palette. Only these colours are used across the app.
enum AuraColor {
    /// Spotify-style accent green for play actions and primary highlights.
    static let green = Color(hex: 0x1DB954)
    static let greenBright = Color(hex: 0x1ED760)

    /// Legacy blue alias remapped to green so the app stays green-first.
    static let blue = greenBright

    /// Adaptive base background (near-black in dark, white in light).
    static let background = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(white: 0.04, alpha: 1) : UIColor(white: 1, alpha: 1)
    })

    /// Slightly raised surface for cards.
    static let surface = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(white: 0.11, alpha: 1) : UIColor(white: 0.95, alpha: 1)
    })

    /// Primary text (white on dark, near-black on light).
    static let textPrimary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 1) : UIColor(white: 0.06, alpha: 1)
    })

    /// Secondary / muted gray text.
    static let textSecondary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(white: 0.62, alpha: 1) : UIColor(white: 0.45, alpha: 1)
    })

    static let hairline = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.08) : UIColor(white: 0, alpha: 0.08)
    })
}

extension View {
    /// Liquid Glass with graceful fallback for pre-iOS 26.
    @ViewBuilder
    func auraGlass(in shape: some Shape = .capsule, tint: Color? = nil, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(glassStyle(tint: tint, interactive: interactive), in: shape)
        } else {
            self.background(shape.fill(.ultraThinMaterial))
                .overlay(shape.stroke(.white.opacity(0.12), lineWidth: 0.5))
        }
    }
}

@available(iOS 26.0, *)
private func glassStyle(tint: Color?, interactive: Bool) -> Glass {
    var glass: Glass = .regular
    if let tint { glass = glass.tint(tint) }
    if interactive { glass = glass.interactive() }
    return glass
}
