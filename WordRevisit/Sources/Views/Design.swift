import SwiftUI

enum Palette {
    static let Background = Color(red: 0.025, green: 0.025, blue: 0.03)
    static let Accent = Color(red: 0.96, green: 0.16, blue: 0.21)
    static let White = Color.white
    static let Muted = Color.white.opacity(0.62)
}

struct AppBackground: View {
    var body: some View {
        ZStack {
            Palette.Background
            RadialGradient(colors: [Palette.Accent.opacity(0.20), .clear], center: .topLeading,
                           startRadius: 30, endRadius: 360)
            RadialGradient(colors: [Palette.White.opacity(0.045), .clear], center: .bottomTrailing,
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
                .overlay(RoundedRectangle(cornerRadius: CornerRadius).stroke(.white.opacity(0.12)))
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
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Tint, in: RoundedRectangle(cornerRadius: 20))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}
