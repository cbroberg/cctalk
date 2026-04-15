//
//  Toast.swift
//  cctalk
//
//  Transient status message. Slides from top safe-area, auto-dismisses.
//  Usage:
//      .toast($toast)  // ToastModel? binding
//

import SwiftUI

public struct ToastModel: Equatable, Identifiable {
    public enum Kind: Equatable {
        case success, error, info
    }
    public let id: UUID
    public let kind: Kind
    public let title: String
    public let subtitle: String?
    public let duration: TimeInterval

    public init(
        id: UUID = UUID(),
        kind: Kind,
        title: String,
        subtitle: String? = nil,
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.subtitle = subtitle
        self.duration = duration ?? (kind == .error ? 3.0 : 1.4)
    }
}

public struct Toast: View {
    public let model: ToastModel

    public var body: some View {
        HStack(spacing: CCSpacing.md) {
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(iconColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(model.title)
                    .font(CCFont.bodyEmphasis)
                    .foregroundStyle(Color.ccTextPrimary)
                if let sub = model.subtitle {
                    Text(sub)
                        .font(CCFont.captionMeta)
                        .foregroundStyle(Color.ccTextSecondary)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, CCSpacing.md)
        .padding(.horizontal, CCSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: CCRadius.sm, style: .continuous)
                .fill(Color.ccBgElevated)
        )
        .overlay(
            RoundedRectangle(cornerRadius: CCRadius.sm, style: .continuous)
                .stroke(Color.ccStrokeSubtle, lineWidth: 1)
        )
        .ccShadow(.toast)
        .padding(.horizontal, CCSpacing.lg)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isStaticText)
    }

    private var iconName: String {
        switch model.kind {
        case .success: return "checkmark.circle.fill"
        case .error:   return "exclamationmark.circle.fill"
        case .info:    return "info.circle.fill"
        }
    }

    private var iconColor: Color {
        switch model.kind {
        case .success: return .ccStatusSuccess
        case .error:   return .ccStatusError
        case .info:    return .ccAccent
        }
    }
}

// MARK: - Presenter modifier

public extension View {
    /// Attach a top-anchored toast that auto-dismisses when its model is non-nil.
    func toast(_ binding: Binding<ToastModel?>) -> some View {
        modifier(ToastPresenter(model: binding))
    }
}

private struct ToastPresenter: ViewModifier {
    @Binding var model: ToastModel?
    @State private var dismissWorkItem: DispatchWorkItem?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let m = model {
                    Toast(model: m)
                        .id(m.id)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .gesture(
                            DragGesture(minimumDistance: 8)
                                .onEnded { g in
                                    if g.translation.height < -12 { dismiss() }
                                }
                        )
                        .onAppear { scheduleDismiss(after: m.duration) }
                        .onTapGesture { dismiss() }
                        .padding(.top, CCSpacing.sm)
                }
            }
            .animation(CCAnimation.springSnappy, value: model?.id)
    }

    private func scheduleDismiss(after seconds: TimeInterval) {
        dismissWorkItem?.cancel()
        let item = DispatchWorkItem { dismiss() }
        dismissWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: item)
    }

    private func dismiss() {
        withAnimation(CCAnimation.springSnappy) { model = nil }
    }
}

// MARK: - Preview

#Preview {
    struct Demo: View {
        @State var toast: ToastModel?
        var body: some View {
            VStack(spacing: CCSpacing.md) {
                Button("Success") {
                    toast = .init(kind: .success, title: "Sendt til cctalk")
                }
                Button("Error") {
                    toast = .init(kind: .error, title: "Kunne ikke sende", subtitle: "503 fra host · Prøv igen")
                }
                Button("Info") {
                    toast = .init(kind: .info, title: "Forbinder igen…")
                }
            }
            .font(CCFont.bodyEmphasis)
            .foregroundStyle(Color.ccAccent)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.ccBgBase)
            .toast($toast)
        }
    }
    return Demo().preferredColorScheme(.dark)
}
