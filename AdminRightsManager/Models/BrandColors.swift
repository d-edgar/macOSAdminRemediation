//
//  BrandColors.swift
//  AdminRightsManager
//
//  Adaptive brand colors — reads a single accent hex from managed
//  preferences and derives all UI colors automatically for both
//  light and dark appearances (follows macOS system setting).
//

import SwiftUI

extension Color {

    // MARK: - Hex Initializer

    /// Creates a Color from a hex string like "#1b386d" or "1b386d"
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }

    // MARK: - HSB Helpers

    /// Lightens a color by increasing brightness
    func lightened(by amount: Double) -> Color {
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? NSColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double(h),
                     saturation: Double(s) * (1.0 - amount * 0.5),
                     brightness: min(Double(b) + amount * (1.0 - Double(b)), 1.0),
                     opacity: Double(a))
    }

    /// Darkens a color by reducing brightness
    func darkened(by amount: Double) -> Color {
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? NSColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double(h),
                     saturation: Double(s),
                     brightness: Double(b) * (1.0 - amount),
                     opacity: Double(a))
    }

    // MARK: - Adaptive Color Factory

    /// Creates a color that adapts to the current macOS appearance.
    /// Provide separate values for light and dark modes.
    private static func adaptive(light: Color, dark: Color) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            if appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua {
                return NSColor(dark)
            } else {
                return NSColor(light)
            }
        })
    }

    // MARK: - Brand Accent (from config profile)

    /// The single configurable accent color — read from "AccentColorHex"
    /// (falls back to legacy "PrimaryColorHex"). Default: #1b386d
    static var brandAccent: Color {
        Color(hex: AppConfiguration.shared.accentColorHex)
    }

    // MARK: - Adaptive UI Colors

    /// Primary accent for buttons, links, and interactive elements.
    /// Slightly lighter in dark mode for better contrast on dark surfaces.
    static var accent: Color {
        adaptive(
            light: brandAccent,
            dark: brandAccent.lightened(by: 0.15)
        )
    }

    /// Window/page background
    static var windowBackground: Color {
        adaptive(
            light: Color(nsColor: .windowBackgroundColor),
            dark: Color(nsColor: .windowBackgroundColor)
        )
    }

    /// Background gradient top
    static var backgroundTop: Color {
        adaptive(
            light: Color(white: 0.96),
            dark: brandAccent.darkened(by: 0.75)
        )
    }

    /// Background gradient bottom
    static var backgroundBottom: Color {
        adaptive(
            light: Color(white: 0.91),
            dark: brandAccent.darkened(by: 0.60)
        )
    }

    /// Header bar background
    static var headerBar: Color {
        adaptive(
            light: brandAccent,
            dark: brandAccent.darkened(by: 0.35)
        )
    }

    /// Header bar text — always white since the header uses the accent color
    static var headerText: Color {
        .white
    }

    /// Card/panel background
    static var cardBackground: Color {
        adaptive(
            light: Color(white: 1.0),
            dark: Color(white: 0.12)
        )
    }

    /// Card/panel border
    static var cardBorder: Color {
        adaptive(
            light: Color(white: 0.85),
            dark: Color(white: 0.2)
        )
    }

    /// Primary text color
    static var textPrimary: Color {
        adaptive(
            light: Color(white: 0.1),
            dark: Color(white: 0.93)
        )
    }

    /// Secondary / muted text
    static var textSecondary: Color {
        adaptive(
            light: Color(white: 0.35),
            dark: Color(white: 0.6)
        )
    }

    /// Tertiary / very muted text (captions, hints)
    static var textTertiary: Color {
        adaptive(
            light: Color(white: 0.5),
            dark: Color(white: 0.4)
        )
    }

    /// Divider / separator lines
    static var divider: Color {
        adaptive(
            light: Color(white: 0.85),
            dark: Color(white: 0.15)
        )
    }

    /// Secondary button background
    static var secondaryButtonBackground: Color {
        adaptive(
            light: Color(white: 0.92),
            dark: Color(white: 0.15)
        )
    }

    /// Secondary button border
    static var secondaryButtonBorder: Color {
        adaptive(
            light: Color(white: 0.78),
            dark: Color(white: 0.25)
        )
    }

    /// Secondary button text
    static var secondaryButtonText: Color {
        adaptive(
            light: Color(white: 0.2),
            dark: Color(white: 0.85)
        )
    }

    /// Info box background (used for callout panels)
    static var infoBoxBackground: Color {
        adaptive(
            light: brandAccent.opacity(0.06),
            dark: brandAccent.opacity(0.12)
        )
    }

    /// Info box border
    static var infoBoxBorder: Color {
        adaptive(
            light: brandAccent.opacity(0.15),
            dark: brandAccent.opacity(0.25)
        )
    }
}
