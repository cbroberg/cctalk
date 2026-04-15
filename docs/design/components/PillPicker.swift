//
//  PillPicker.swift
//  cctalk
//
//  Horizontal swipeable session picker. The hero interaction of the app.
//  - Tap a pill to select it.
//  - Horizontal swipe scrolls the rail and snaps the nearest pill under the
//    invisible center indicator (handled by ScrollView + scrollTargetBehavior).
//  - External drag on the main canvas can drive `selectedID` ±1 to change
//    pill from anywhere on screen (wired up by the parent view).
//

import SwiftUI

public struct Session: Identifiable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let isLive: Bool
    public init(id: String, name: String, isLive: Bool = true) {
        self.id = id
        self.name = name
        self.isLive = isLive
    }
}

public struct PillPicker: View {
    public let sessions: [Session]
    @Binding public var selectedID: Session.ID?

    public init(sessions: [Session], selectedID: Binding<Session.ID?>) {
        self.sessions = sessions
        self._selectedID = selectedID
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: CCSpacing.sm) {
                    ForEach(sessions) { session in
                        Pill(
                            session: session,
                            isSelected: session.id == selectedID
                        ) {
                            select(session.id, proxy: proxy)
                        }
                        .id(session.id)
                    }
                }
                .padding(.horizontal, CCSpacing.lg)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .contentMargins(.horizontal, CCSpacing.lg, for: .scrollContent)
            .onChange(of: selectedID) { _, new in
                guard let new else { return }
                withAnimation(CCAnimation.springSnappy) {
                    proxy.scrollTo(new, anchor: .center)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Sessioner")
        }
    }

    private func select(_ id: Session.ID, proxy: ScrollViewProxy) {
        guard selectedID != id else { return }
        Haptics.selection()
        withAnimation(CCAnimation.springSnappy) {
            selectedID = id
            proxy.scrollTo(id, anchor: .center)
        }
    }
}

// MARK: - Pill

private struct Pill: View {
    let session: Session
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: CCSpacing.xs) {
                if !session.isLive {
                    Circle()
                        .fill(Color.ccStatusOffline)
                        .frame(width: 6, height: 6)
                }
                Text(session.name)
                    .font(CCFont.bodyEmphasis)
                    .lineLimit(1)
                    .foregroundStyle(isSelected ? Color.ccTextOnAccent : Color.ccTextPrimary)
            }
            .padding(.horizontal, CCSpacing.lg)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: CCRadius.pill, style: .continuous)
                    .fill(isSelected ? Color.ccAccent : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CCRadius.pill, style: .continuous)
                    .stroke(isSelected ? Color.clear : Color.ccStrokeSubtle, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(CCAnimation.springSnappy, value: isPressed)
            .animation(CCAnimation.springDefault, value: isSelected)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .accessibilityLabel(session.name)
        .accessibilityValue(isSelected ? "valgt" : "")
        .accessibilityHint("Dobbelttap for at skifte session")
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
    }
}

// MARK: - Preview

#Preview {
    struct Demo: View {
        @State var selected: String? = "cctalk"
        let sessions: [Session] = [
            .init(id: "cms",    name: "cms"),
            .init(id: "whop",   name: "whop"),
            .init(id: "cctalk", name: "cctalk"),
            .init(id: "dnsmcp", name: "dnsmcp"),
            .init(id: "cron",   name: "cronjobs", isLive: false),
        ]
        var body: some View {
            PillPicker(sessions: sessions, selectedID: $selected)
                .padding(.vertical, CCSpacing.md)
                .background(Color.ccBgBase)
        }
    }
    return Demo().preferredColorScheme(.dark)
}
