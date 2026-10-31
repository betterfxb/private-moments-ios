import SwiftUI
import UIKit

enum AppColors {
    static let cream = adaptive(
        light: UIColor(red: 1.00, green: 0.973, blue: 0.945, alpha: 1),
        dark: UIColor(red: 0.090, green: 0.075, blue: 0.070, alpha: 1)
    )
    static let paper = adaptive(
        light: UIColor(red: 1.00, green: 0.992, blue: 0.973, alpha: 1),
        dark: UIColor(red: 0.137, green: 0.110, blue: 0.102, alpha: 1)
    )
    static let sand = adaptive(
        light: UIColor(red: 0.925, green: 0.820, blue: 0.737, alpha: 1),
        dark: UIColor(red: 0.490, green: 0.361, blue: 0.298, alpha: 1)
    )
    static let blush = adaptive(
        light: UIColor(red: 0.902, green: 0.675, blue: 0.635, alpha: 1),
        dark: UIColor(red: 0.620, green: 0.365, blue: 0.337, alpha: 1)
    )
    static let terracotta = adaptive(
        light: UIColor(red: 0.700, green: 0.340, blue: 0.310, alpha: 1),
        dark: UIColor(red: 0.620, green: 0.278, blue: 0.255, alpha: 1)
    )
    static let terracottaDark = adaptive(
        light: UIColor(red: 0.655, green: 0.310, blue: 0.290, alpha: 1),
        dark: UIColor(red: 0.925, green: 0.690, blue: 0.635, alpha: 1)
    )
    static let ink = adaptive(
        light: UIColor(red: 0.227, green: 0.157, blue: 0.165, alpha: 1),
        dark: UIColor(red: 0.965, green: 0.922, blue: 0.890, alpha: 1)
    )
    static let inkSoft = adaptive(
        light: UIColor(red: 0.455, green: 0.365, blue: 0.357, alpha: 1),
        dark: UIColor(red: 0.780, green: 0.710, blue: 0.675, alpha: 1)
    )
    static let line = adaptive(
        light: UIColor(red: 0.918, green: 0.851, blue: 0.800, alpha: 1),
        dark: UIColor(red: 0.310, green: 0.255, blue: 0.235, alpha: 1)
    )
    static let espresso = adaptive(
        light: UIColor(red: 0.200, green: 0.145, blue: 0.153, alpha: 1),
        dark: UIColor(red: 0.055, green: 0.040, blue: 0.040, alpha: 1)
    )
    static let sage = adaptive(
        light: UIColor(red: 0.310, green: 0.430, blue: 0.340, alpha: 1),
        dark: UIColor(red: 0.620, green: 0.745, blue: 0.615, alpha: 1)
    )

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? dark : light
        })
    }
}

enum AppSpacing {
    static let page: CGFloat = 22
    static let section: CGFloat = 24
    static let card: CGFloat = 16
    static let compact: CGFloat = 10
}

enum AppRadius {
    static let card: CGFloat = 20
    static let control: CGFloat = 14
    static let pill: CGFloat = 999
}

struct PrimaryActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded).weight(.semibold))
            .foregroundStyle(AppColors.paper)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(AppColors.terracotta.opacity(isEnabled ? 1 : 0.55), in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .scaleEffect(isEnabled && configuration.isPressed ? 0.985 : 1)
            .opacity(isEnabled && configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}
