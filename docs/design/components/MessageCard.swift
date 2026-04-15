//
//  MessageCard.swift
//  cctalk
//
//  A single history row: status glyph · target · time · body.
//  - Tap to resend (parent handles the network call).
//  - Leading-swipe reveals delete; swipeActions gives system-standard feel.
//

import SwiftUI

public struct Message: Identifiable, Equatable, Hashable {
    public enum Status: Equatable, Hashable {
        case sent
        case failed(String)
    }
    public let id: UUID
    public let target: String
    public let text: String
    public let date: Date
    public let status: Status

    public init(id: UUID = UUID(),
                target: String,
                text: String,
                date: Date = .now,
                status: Status = .sent) {
        self.id = id
        self.target = target
        self.text = text
        self.date = date
        self.status = status
    }
}

public struct MessageCard: View {
    public let message: Message
    public var onResend: (Message) -> Void = { _ in }
    public var onDelete: (Message) -> Void = { _ in }

    public init(
        message: Message,
        onResend: @escaping (Message) -> Void = { _ in },
        onDelete: @escaping (Message) -> Void = { _ in }
    ) {
        self.message = message
        self.onResend = onResend
        self.onDelete = onDelete
    }

    @State private var isPressed = false

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    public var body: some View {
        Button {
            Haptics.impact(.light, intensity: 0.5)
            onResend(message)
        } label: {
            HStack(alignment: .top, spacing: CCSpacing.md) {
                statusGlyph
                    .padding(.top, 2)
                VStack(alignment: .leading, spacing: CCSpacing.xs) {
                    HStack(spacing: CCSpacing.sm) {
                        Text(message.target)
                            .font(CCFont.captionMeta)
                            .foregroundStyle(Color.ccTextSecondary)
                        Text("·")
                            .font(CCFont.captionMeta)
                            .foregroundStyle(Color.ccTextTertiary)
                        Text(Self.timeFormatter.string(from: message.date))
                            .font(CCFont.captionMeta)
                            .foregroundStyle(Color.ccTextTertiary)
                        if case .failed(let reason) = message.status {
                            Text("· \(reason)")
                                .font(CCFont.captionMeta)
                                .foregroundStyle(Color.ccStatusError)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                    Text(message.text)
                        .font(CCFont.bodyDefault)
                        .foregroundStyle(Color.ccTextPrimary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }
            }
            .padding(CCSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous)
                    .fill(Color.ccBgElevated)
            )
            .overlay(
                RoundedRectangle(cornerRadius: CCRadius.md, style: .continuous)
                    .stroke(Color.ccStrokeSubtle, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.985 : 1.0)
            .animation(CCAnimation.springSnappy, value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                Haptics.impact(.rigid, intensity: 0.5)
                onDelete(message)
            } label: {
                Label("Slet", systemImage: "trash")
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Dobbelttap for at sende igen")
        .accessibilityAction(named: "Send igen") { onResend(message) }
        .accessibilityAction(named: "Slet") { onDelete(message) }
    }

    private var statusGlyph: some View {
        Group {
            switch message.status {
            case .sent:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.ccStatusSuccess)
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(Color.ccStatusError)
            }
        }
        .font(.system(size: 16, weight: .semibold))
        .accessibilityHidden(true)
    }

    private var accessibilityLabel: String {
        let status: String = {
            switch message.status {
            case .sent:       return "Sendt"
            case .failed(let r): return "Fejlede: \(r)"
            }
        }()
        return "\(status) til \(message.target) klokken \(Self.timeFormatter.string(from: message.date)). Besked: \(message.text)"
    }
}

// MARK: - Preview

#Preview {
    List {
        MessageCard(message: .init(target: "cctalk", text: "test fra iphone"))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        MessageCard(message: .init(target: "cms",    text: "kør typecheck og fix evt. fejl"))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        MessageCard(message: .init(target: "whop",   text: "Fejl fra host",
                                   status: .failed("503")))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(Color.ccBgBase)
    .preferredColorScheme(.dark)
}
