import SwiftUI
import UIKit

enum AppColors {
    static let background = adaptive(light: 0xFBF6F8, dark: 0x171317)
    static let surface = adaptive(light: 0xFFFFFF, dark: 0x241E24)
    static let accent = Color(uiColor: color(0xB34165))
    static let accentText = adaptive(light: 0xA5375B, dark: 0xF3A5BE)
    static let accentWash = adaptive(light: 0xF7E5ED, dark: 0x3C2733)
    static let text = adaptive(light: 0x30262D, dark: 0xF8EFF4)
    static let secondaryText = adaptive(light: 0x75656F, dark: 0xBEADB8)
    static let separator = adaptive(light: 0xECDDE4, dark: 0x493641)
    static let success = adaptive(light: 0x42654D, dark: 0x9AC9AA)
    // Session and saturated-action foregrounds do not adapt to the page surface.
    static let session = Color(uiColor: color(0x20151F))
    static let onAccent = Color.white
    static let onDark = Color(uiColor: color(0xFFF5F9))
    static let onDarkSecondary = Color(uiColor: color(0xCCB8C5))
    static let onDarkAccent = Color(uiColor: color(0xF3A5BE))

    private static func color(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                green: CGFloat((hex >> 8) & 255) / 255,
                blue: CGFloat(hex & 255) / 255, alpha: 1)
    }

    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            color(traits.userInterfaceStyle == .dark ? dark : light)
        })
    }
}

enum AppSpacing {
    static let page: CGFloat = 20
    static let section: CGFloat = 24
    static let card: CGFloat = 16
    static let compact: CGFloat = 10
}

enum AppRadius {
    static let card: CGFloat = 22
    static let control: CGFloat = 16
    static let pill: CGFloat = 999
}

struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(AppColors.onAccent)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .frame(minHeight: 50)
            .background(AppColors.accent.opacity(isEnabled ? 1 : 0.55), in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .scaleEffect(isEnabled && configuration.isPressed && !reduceMotion ? 0.985 : 1)
            .opacity(isEnabled && configuration.isPressed ? 0.92 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

/// A content surface. Navigation materials remain the system's responsibility.
struct JournalPanel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surface, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(AppColors.separator.opacity(0.6), lineWidth: 0.5)
            }
    }
}

struct SecondaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(AppColors.accentText)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 15)
            .frame(minHeight: 50)
            .background(AppColors.accentWash, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .opacity(!isEnabled ? 0.5 : (configuration.isPressed ? 0.72 : 1))
    }
}
