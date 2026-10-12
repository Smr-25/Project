import SwiftUI

enum Palette {
    static let Background = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.025, green: 0.025, blue: 0.03, alpha: 1)
        : UIColor(red: 0.96, green: 0.965, blue: 0.975, alpha: 1) })
    static let Primary = Color(uiColor: .label)
    static let Muted = Color(uiColor: .secondaryLabel)
    static let Accent = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.49, green: 0.69, blue: 0.94, alpha: 1)
        : UIColor(red: 0.18, green: 0.38, blue: 0.66, alpha: 1) })
    static let Success = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark
        ? UIColor(red: 0.47, green: 0.79, blue: 0.65, alpha: 1)
        : UIColor(red: 0.12, green: 0.43, blue: 0.30, alpha: 1) })
    static let Danger = Color(uiColor: .systemRed)
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
            .foregroundStyle(Palette.Muted)
    }
}

struct PrimaryActionStyle: ButtonStyle {
    let Tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundStyle(Palette.Background)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(Tint, in: RoundedRectangle(cornerRadius: 20))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
