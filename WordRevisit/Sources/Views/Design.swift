import SwiftUI

enum Palette {
    static let Background = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.025, green: 0.025, blue: 0.03, alpha: 1)
        : UIColor(red: 0.96, green: 0.965, blue: 0.975, alpha: 1) })
    static let Primary = Color(uiColor: .label)
    static let Muted = Color(uiColor: .secondaryLabel)
    static let Accent = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.96, green: 0.16, blue: 0.21, alpha: 1)
        : UIColor(red: 0.82, green: 0.08, blue: 0.13, alpha: 1) })
    static let Success = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.20, green: 0.78, blue: 0.55, alpha: 1)
        : UIColor(red: 0.02, green: 0.43, blue: 0.28, alpha: 1) })
    static let Danger = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.96, green: 0.35, blue: 0.46, alpha: 1)
        : UIColor(red: 0.66, green: 0.06, blue: 0.19, alpha: 1) })
}

extension AppAppearance {
    var ColorScheme: ColorScheme? {
        switch self {
        case .System: nil
        case .Light: .light
        case .Dark: .dark
        }
    }
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            Palette.Background
            RadialGradient(colors: [Palette.Accent.opacity(0.07), .clear], center: .topLeading,
                           startRadius: 30, endRadius: 360)
            RadialGradient(colors: [Palette.Primary.opacity(0.045), .clear], center: .bottomTrailing,
                           startRadius: 10, endRadius: 330)
        }
        .ignoresSafeArea()
    }
}

extension View {
    @ViewBuilder
    func FrostedCard(CornerRadius: CGFloat = 28) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.regular, in: RoundedRectangle(cornerRadius: CornerRadius))
        } else {
            self.background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: CornerRadius))
                .overlay(RoundedRectangle(cornerRadius: CornerRadius).stroke(Palette.Primary.opacity(0.08)))
        }
    }
}

struct SectionEyebrow: View {
    let Title: String

    var body: some View {
        Text(Title.uppercased())
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .tracking(2.6)
            .foregroundStyle(Palette.Accent)
    }
}

struct PrimaryActionStyle: ButtonStyle {
    @Environment(\.isEnabled) private var IsEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Palette.Accent.opacity(IsEnabled ? 1 : 0.4), in: RoundedRectangle(cornerRadius: 20))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
