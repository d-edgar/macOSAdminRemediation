//
//  BrandColors.swift
//  AdminRightsManager
//
//  Brand colors — reads hex values from the managed preferences
//  (config profile) so any organization can set their own palette.
//  Falls back to defaults if no config profile is deployed.
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

    /// Darkens a color by a percentage (0.0 = unchanged, 1.0 = black)
    func darkened(by amount: Double) -> Color {
        let nsColor = NSColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return Color(hue: Double(h),
                     saturation: Double(s),
                     brightness: Double(b) * (1.0 - amount),
                     opacity: Double(a))
    }

    // MARK: - Configurable Brand Colors

    /// Primary brand color — read from config profile key "PrimaryColorHex"
    /// Default: #1b386d
    static var brandPrimary: Color {
        Color(hex: AppConfiguration.shared.primaryColorHex)
    }

    /// Secondary brand color — read from config profile key "SecondaryColorHex"
    /// Default: #84888b
    static var brandSecondary: Color {
        Color(hex: AppConfiguration.shared.secondaryColorHex)
    }

    /// Dark brand color — read from config profile key "DarkColorHex"
    /// Default: #172951
    static var brandDark: Color {
        Color(hex: AppConfiguration.shared.darkColorHex)
    }

    // MARK: - Derived UI Colors (computed from brand colors)

    /// Background gradient top
    static var backgroundTop: Color {
        brandDark.darkened(by: 0.35)
    }

    /// Background gradient bottom
    static var backgroundBottom: Color {
        brandDark
    }

    /// Header bar background
    static var headerBar: Color {
        brandDark.darkened(by: 0.15)
    }

    /// Card/panel background
    static var cardBackground: Color {
        brandDark.darkened(by: 0.25)
    }
}
