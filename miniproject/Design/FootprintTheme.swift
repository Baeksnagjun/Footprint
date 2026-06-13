//
//  FootprintTheme.swift
//  Footprint
//

import SwiftUI

enum FootprintTheme {
    static let neonCyan = Color(red: 0.0, green: 0.82, blue: 0.72)
    static let neonCyanDeep = Color(red: 0.0, green: 0.62, blue: 0.55)

    static let background = Color(red: 0.96, green: 0.98, blue: 0.99)
    static let backgroundTint = Color(red: 0.88, green: 0.97, blue: 0.95)

    static let surface = Color.white
    static let surfaceElevated = Color(red: 0.94, green: 0.98, blue: 0.97)

    static let textPrimary = Color(red: 0.11, green: 0.15, blue: 0.20)
    static let textSecondary = Color(red: 0.35, green: 0.42, blue: 0.48)
    static let textMuted = Color(red: 0.55, green: 0.61, blue: 0.66)

    static let mapGrid = Color(red: 0.82, green: 0.88, blue: 0.90)
    static let campusBoundary = neonCyan.opacity(0.55)
    static let cardStroke = neonCyan.opacity(0.22)
    static let buttonOnAccent = Color(red: 0.04, green: 0.20, blue: 0.18)
}

struct FootprintPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(FootprintTheme.buttonOnAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(FootprintTheme.neonCyan.opacity(configuration.isPressed ? 0.8 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

struct FootprintCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(FootprintTheme.surface)
                    .shadow(color: .black.opacity(0.06), radius: 12, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(FootprintTheme.cardStroke, lineWidth: 1)
            )
    }
}

extension View {
    func footprintCard(cornerRadius: CGFloat = 16) -> some View {
        modifier(FootprintCardModifier(cornerRadius: cornerRadius))
    }
}

struct FootprintSearchField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(FootprintTheme.textMuted)
            TextField(placeholder, text: $text)
                .foregroundStyle(FootprintTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(FootprintTheme.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(FootprintTheme.cardStroke, lineWidth: 1)
        )
    }
}
