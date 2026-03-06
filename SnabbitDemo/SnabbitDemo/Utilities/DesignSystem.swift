import SwiftUI

// MARK: - Color Palette
extension Color {
    static let appPrimary = Color(hex: "#3D35B0")       // Deep purple
    static let appPrimaryLight = Color(hex: "#5B52D6")
    static let appBackground = Color(hex: "#FFFFFF")
    static let appSurface = Color(hex: "#F8F8FC")
    static let appBorder = Color(hex: "#E5E5EF")
    static let appTextPrimary = Color(hex: "#1A1A2E")
    static let appTextSecondary = Color(hex: "#6B6B8A")
    static let appTextPlaceholder = Color(hex: "#ADADC4")
    static let appRed = Color(hex: "#E53935")
    static let appSuccess = Color(hex: "#43A047")

    // Break screen gradient
    static let breakGradientTop = Color(hex: "#3D35B0")
    static let breakGradientBottom = Color(hex: "#5B52D6")
    static let breakCardBackground = Color(hex: "#4A41C0")
}

// MARK: - Hex Color Init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}

// MARK: - Typography
struct AppFont {
    static func regular(_ size: CGFloat) -> Font { .system(size: size, weight: .regular) }
    static func medium(_ size: CGFloat) -> Font { .system(size: size, weight: .medium) }
    static func semibold(_ size: CGFloat) -> Font { .system(size: size, weight: .semibold) }
    static func bold(_ size: CGFloat) -> Font { .system(size: size, weight: .bold) }
}

// MARK: - Spacing
enum AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Corner Radius
enum AppRadius {
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 24
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.semibold(16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isEnabled ? Color.appPrimary : Color.appTextPlaceholder)
            .cornerRadius(AppRadius.md)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct DestructiveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.semibold(16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(Color.appRed)
            .cornerRadius(AppRadius.md)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppFont.semibold(16))
            .foregroundColor(.appPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md)
                    .stroke(Color.appPrimary, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
