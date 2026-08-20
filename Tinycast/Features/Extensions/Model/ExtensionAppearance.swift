import Foundation

/// A native-looking stand-in for whatever icon an extension shipped: an SF Symbol from a curated set,
/// on a tinted tile. Chosen in Settings › Extensions, applied to every command of that extension.
struct ExtensionAppearance: Codable, Equatable, Hashable, Sendable {
    var symbol: String
    var tint: ExtensionTint

    static let fallback = ExtensionAppearance(symbol: "puzzlepiece.extension", tint: .purple)
}

/// The tile colours on offer — the same family the Settings sidebar uses, so an overridden extension
/// looks like it belongs rather than like a sticker.
enum ExtensionTint: String, CaseIterable, Identifiable, Codable, Sendable {
    // Declaration order is swatch order: around the wheel, then the earths and neutrals.
    case red, maroon, rose, pink, purple, indigo, blue, cyan, teal, mint
    case green, lime, yellow, orange, tan, brown, gray, slate

    var id: String { rawValue }

    /// Shown as the swatch tooltip — "tan" alone doesn't say much.
    var title: String {
        switch self {
        case .red: return String(localized: "Red")
        case .maroon: return String(localized: "Maroon")
        case .rose: return String(localized: "Rose")
        case .pink: return String(localized: "Pink")
        case .purple: return String(localized: "Purple")
        case .indigo: return String(localized: "Indigo")
        case .blue: return String(localized: "Blue")
        case .cyan: return String(localized: "Cyan")
        case .teal: return String(localized: "Teal")
        case .mint: return String(localized: "Mint")
        case .green: return String(localized: "Green")
        case .lime: return String(localized: "Lime")
        case .yellow: return String(localized: "Yellow")
        case .orange: return String(localized: "Orange")
        case .tan: return String(localized: "Light Brown")
        case .brown: return String(localized: "Brown")
        case .gray: return String(localized: "Gray")
        case .slate: return String(localized: "Slate")
        }
    }
}
