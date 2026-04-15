//
//  Theme.swift
//  cctalk
//
//  Design tokens: color, typography, spacing, radius, duration, haptics.
//  See DESIGN.md for the full system. Keep this file and that doc in lockstep.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Color

public extension Color {
    // Accent
    static let ccAccent         = Color("ccAccent",         bundle: nil, default: .init(hex: 0x3B82F6), light: .init(hex: 0x2563EB))
    static let ccAccentMuted    = Color("ccAccentMuted",    bundle: nil, default: .init(hex: 0x1E3A8A), light: .init(hex: 0xDBEAFE))
    static let ccAccentPressed  = Color("ccAccentPressed",  bundle: nil, default: .init(hex: 0x60A5FA), light: .init(hex: 0x1D4ED8))

    // Backgrounds
    static let ccBgBase         = Color("ccBgBase",         bundle: nil, default: .init(hex: 0x0B0B0F), light: .init(hex: 0xF7F7F8))
    static let ccBgElevated     = Color("ccBgElevated",     bundle: nil, default: .init(hex: 0x16161C), light: .init(hex: 0xFFFFFF))
    static let ccBgOverlay      = Color.white.opacity(0.06)
    static let ccBgScrim        = Color.black.opacity(0.6)

    // Text
    static let ccTextPrimary    = Color("ccTextPrimary",    bundle: nil, default: .init(hex: 0xF5F5F7), light: .init(hex: 0x0B0B0F))
    static let ccTextSecondary  = Color("ccTextSecondary",  bundle: nil, default: .init(hex: 0xA1A1AA), light: .init(hex: 0x44444C))
    static let ccTextTertiary   = Color("ccTextTertiary",   bundle: nil, default: .init(hex: 0x6B6B74), light: .init(hex: 0x7A7A85))
    static let ccTextOnAccent   = Color.white

    // Strokes
    static let ccStrokeSubtle   = Color("ccStrokeSubtle",   bundle: nil, default: .init(hex: 0x26262E), light: .init(hex: 0xE5E5EA))
    static let ccStrokeStrong   = Color("ccStrokeStrong",   bundle: nil, default: .init(hex: 0x3A3A42), light: .init(hex: 0xC7C7CC))

    // Status
    static let ccStatusSuccess  = Color("ccStatusSuccess",  bundle: nil, default: .init(hex: 0x22C55E), light: .init(hex: 0x16A34A))
    static let ccStatusError    = Color("ccStatusError",    bundle: nil, default: .init(hex: 0xF87171), light: .init(hex: 0xDC2626))
    static let ccStatusWarn     = Color("ccStatusWarn",     bundle: nil, default: .init(hex: 0xFBBF24), light: .init(hex: 0xD97706))
    static let ccStatusOffline  = Color("ccStatusOffline",  bundle: nil, default: .init(hex: 0x6B6B74), light: .init(hex: 0x7A7A85))
}

// MARK: - Color helpers

extension Color {
    /// Init from 0xRRGGBB hex literal.
    init(hex: UInt32, alpha: Double = 1.0) {
        let r = Double((hex >> 16) & 0xFF) / 255.0
        let g = Double((hex >> 8)  & 0xFF) / 255.0
        let b = Double( hex        & 0xFF) / 255.0
        self = Color(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }

    /// Dynamic color: uses Asset Catalog entry if present, otherwise resolves per userInterfaceStyle.
    fileprivate init(_ name: String, bundle: Bundle?, default darkDefault: Color, light lightDefault: Color) {
#if canImport(UIKit)
        if UIColor(named: name, in: bundle, compatibleWith: nil) != nil {
            self = Color(name, bundle: bundle)
            return
        }
        self = Color(uiColor: UIColor { trait in
            switch trait.userInterfaceStyle {
            case .light: return UIColor(lightDefault)
            default:     return UIColor(darkDefault)
            }
        })
#else
        self = darkDefault
#endif
    }
}

// MARK: - Typography

public enum CCFont {
    public static let displayLarge   = Font.system(size: 34, weight: .bold,     design: .default)
    public static let titleHeader    = Font.system(size: 22, weight: .semibold, design: .default)
    public static let titleSection   = Font.system(size: 17, weight: .semibold, design: .default)
    public static let bodyDefault    = Font.system(size: 17, weight: .regular,  design: .default)
    public static let bodyEmphasis   = Font.system(size: 17, weight: .medium,   design: .default)
    public static let calloutLive    = Font.system(size: 20, weight: .regular,  design: .default)
    public static let captionMeta    = Font.system(size: 13, weight: .regular,  design: .default)
    public static let footnoteMicro  = Font.system(size: 11, weight: .medium,   design: .default)
    public static let monoToken      = Font.system(size: 13, weight: .regular,  design: .monospaced)
}

// MARK: - Spacing

public enum CCSpacing {
    public static let xxs:  CGFloat = 2
    public static let xs:   CGFloat = 4
    public static let sm:   CGFloat = 8
    public static let md:   CGFloat = 12
    public static let lg:   CGFloat = 16
    public static let xl:   CGFloat = 24
    public static let xxl:  CGFloat = 32
    public static let huge: CGFloat = 48
}

// MARK: - Radius

public enum CCRadius {
    public static let xs:   CGFloat = 4
    public static let sm:   CGFloat = 8
    public static let md:   CGFloat = 12
    public static let lg:   CGFloat = 16
    public static let pill: CGFloat = 999
}

// MARK: - Animation

public enum CCAnimation {
    public static let springSnappy  = Animation.spring(response: 0.28, dampingFraction: 0.82)
    public static let springDefault = Animation.spring(response: 0.35, dampingFraction: 0.70)
    public static let springBouncy  = Animation.spring(response: 0.45, dampingFraction: 0.60)
    public static let easeQuick     = Animation.easeOut(duration: 0.18)
    public static let easeGentle    = Animation.easeInOut(duration: 0.24)
    public static let pulse         = Animation.easeInOut(duration: 1.1).repeatForever(autoreverses: true)
    public static let shimmer       = Animation.linear(duration: 1.4).repeatForever(autoreverses: false)
}

// MARK: - Haptics

public enum HapticsLevel: String, CaseIterable, Identifiable {
    case all, minimal, off
    public var id: String { rawValue }
}

public enum Haptics {
    /// Read from `@AppStorage("hapticsLevel")` at call sites; default `.all`.
    public static var level: HapticsLevel = .all

    public static func selection() {
#if canImport(UIKit)
        guard level != .off else { return }
        UISelectionFeedbackGenerator().selectionChanged()
#endif
    }

    public static func impact(_ style: ImpactStyle, intensity: CGFloat = 1.0) {
#if canImport(UIKit)
        guard level != .off else { return }
        if level == .minimal && style != .medium { return }
        let gen = UIImpactFeedbackGenerator(style: style.uiStyle)
        gen.impactOccurred(intensity: intensity)
#endif
    }

    public static func success() {
#if canImport(UIKit)
        guard level != .off else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
#endif
    }

    public static func error() {
#if canImport(UIKit)
        guard level != .off else { return }
        UINotificationFeedbackGenerator().notificationOccurred(.error)
#endif
    }

    public enum ImpactStyle {
        case light, medium, heavy, soft, rigid
#if canImport(UIKit)
        var uiStyle: UIImpactFeedbackGenerator.FeedbackStyle {
            switch self {
            case .light:  return .light
            case .medium: return .medium
            case .heavy:  return .heavy
            case .soft:   return .soft
            case .rigid:  return .rigid
            }
        }
#endif
    }
}

// MARK: - Shadows

public struct CCShadow {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat

    public static let card  = CCShadow(color: .black.opacity(0.25), radius: 12, x: 0, y: 6)
    public static let toast = CCShadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
}

public extension View {
    func ccShadow(_ s: CCShadow) -> some View {
        self.shadow(color: s.color, radius: s.radius, x: s.x, y: s.y)
    }
}
