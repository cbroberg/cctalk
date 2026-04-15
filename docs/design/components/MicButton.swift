//
//  MicButton.swift
//  cctalk
//
//  Circular mic with explicit state machine.
//  idle  ─press──▶ listening ─release──▶ sending ─ok──▶ success ──1.4s──▶ idle
//                                         │
//                                         └─err─▶ error ──tap──▶ idle
//

import SwiftUI

public enum MicState: Equatable {
    case idle
    case listening
    case sending
    case success
    case error(String)

    var accessibilityValue: String {
        switch self {
        case .idle:       return "Klar"
        case .listening:  return "Lytter"
        case .sending:    return "Sender"
        case .success:    return "Sendt"
        case .error(let m): return "Fejl: \(m)"
        }
    }
}

public struct MicButton: View {
    @Binding public var state: MicState
    public var size: CGFloat = 200
    public var onPressBegan: () -> Void = {}
    public var onPressEnded: () -> Void = {}
    public var onErrorDismiss: () -> Void = {}

    public init(
        state: Binding<MicState>,
        size: CGFloat = 200,
        onPressBegan: @escaping () -> Void = {},
        onPressEnded: @escaping () -> Void = {},
        onErrorDismiss: @escaping () -> Void = {}
    ) {
        self._state = state
        self.size = size
        self.onPressBegan = onPressBegan
        self.onPressEnded = onPressEnded
        self.onErrorDismiss = onErrorDismiss
    }

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulse = false
    @State private var shimmerPhase: CGFloat = 0
    @GestureState private var isPressing = false

    public var body: some View {
        ZStack {
            halo
            base
            icon
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(pressGesture)
        .onTapGesture {
            if case .error = state { onErrorDismiss() }
        }
        .onChange(of: state) { _, new in handleStateChange(new) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Tal besked")
        .accessibilityValue(state.accessibilityValue)
        .accessibilityHint("Dobbelttap og hold for at diktere")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Layers

    private var halo: some View {
        Circle()
            .fill(Color.ccAccentMuted)
            .frame(width: size, height: size)
            .scaleEffect(state == .listening ? (pulse ? 1.18 : 1.02) : 1.0)
            .opacity(state == .listening ? 0.55 : 0)
            .animation(reduceMotion ? CCAnimation.easeQuick : CCAnimation.pulse,
                       value: pulse)
            .animation(CCAnimation.springDefault, value: state)
    }

    private var base: some View {
        Circle()
            .fill(fillColor)
            .overlay(
                // 8% top-highlight -> bottom-shade linear depth wash.
                LinearGradient(
                    colors: [Color.white.opacity(0.08), Color.black.opacity(0.08)],
                    startPoint: .top, endPoint: .bottom
                )
                .clipShape(Circle())
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
            .overlay(
                // Sending shimmer ring.
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(Color.ccTextOnAccent.opacity(0.9),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(Double(shimmerPhase) * 360))
                    .opacity(state == .sending ? 1 : 0)
                    .animation(reduceMotion ? nil : CCAnimation.shimmer, value: shimmerPhase)
            )
            .scaleEffect(isPressing ? 0.95 : 1.0)
            .animation(CCAnimation.springBouncy, value: isPressing)
            .animation(CCAnimation.easeGentle, value: fillColor)
    }

    private var icon: some View {
        Group {
            switch state {
            case .idle:
                Image(systemName: "mic.fill")
            case .listening:
                Image(systemName: "waveform")
                    .symbolEffect(.variableColor.iterative, options: .repeating)
            case .sending:
                Image(systemName: "arrow.up")
            case .success:
                Image(systemName: "checkmark")
            case .error:
                Image(systemName: "exclamationmark")
            }
        }
        .font(.system(size: size * 0.36, weight: .semibold))
        .foregroundStyle(Color.ccTextOnAccent)
        .contentTransition(.symbolEffect(.replace))
        .animation(CCAnimation.springDefault, value: state)
    }

    // MARK: - Style

    private var fillColor: Color {
        switch state {
        case .idle, .listening, .sending: return Color.ccAccent
        case .success:                    return Color.ccStatusSuccess
        case .error:                      return Color.ccStatusError
        }
    }

    // MARK: - Gestures

    private var pressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.0)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .updating($isPressing) { value, out, _ in
                switch value {
                case .second(true, _): out = true
                default:               out = false
                }
            }
            .onChanged { value in
                if case .first = value {
                    // ignore
                } else if case .second(true, _) = value, state == .idle {
                    Haptics.impact(.medium)
                    onPressBegan()
                }
            }
            .onEnded { _ in
                if state == .listening {
                    Haptics.impact(.soft, intensity: 0.6)
                    onPressEnded()
                }
            }
    }

    // MARK: - Side effects

    private func handleStateChange(_ new: MicState) {
        switch new {
        case .listening:
            if !reduceMotion { pulse = true }
        case .sending:
            pulse = false
            if !reduceMotion {
                shimmerPhase = 0
                withAnimation(CCAnimation.shimmer) { shimmerPhase = 1 }
            }
        case .success:
            pulse = false
            Haptics.success()
        case .error:
            pulse = false
            Haptics.error()
        case .idle:
            pulse = false
        }
    }
}

// MARK: - Preview

#Preview {
    struct Demo: View {
        @State var state: MicState = .idle
        var body: some View {
            VStack(spacing: CCSpacing.xxl) {
                MicButton(state: $state,
                          onPressBegan: { state = .listening },
                          onPressEnded: {
                              state = .sending
                              DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                                  state = .success
                                  DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                                      state = .idle
                                  }
                              }
                          },
                          onErrorDismiss: { state = .idle })
                HStack {
                    Button("Err") { state = .error("503") }
                    Button("Idle") { state = .idle }
                }.font(CCFont.captionMeta)
            }
            .padding(CCSpacing.xxl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.ccBgBase)
        }
    }
    return Demo().preferredColorScheme(.dark)
}
