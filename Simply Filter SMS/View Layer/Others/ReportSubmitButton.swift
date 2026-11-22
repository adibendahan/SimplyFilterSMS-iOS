//
//  ReportSubmitButton.swift
//  Simply Filter SMS
//

import SwiftUI


//MARK: - Motion -
private enum ReportSubmitMotion {
    static let fallbackHeight: CGFloat = 50
    static let checkFont = Font.title3.weight(.bold)
    static let checkDelay: Double = 0.05
    static let checkDuration: Double = 0.3
    static let spinnerStartScale: CGFloat = 0.4
}


//MARK: - View -
struct ReportSubmitButton: View {

    enum Phase: Equatable {
        case idle, sending, done
    }

    let phase: Phase
    let action: () -> Void

    @State private var height: CGFloat = ReportSubmitMotion.fallbackHeight

    var body: some View {
        ZStack {
            if self.phase == .idle {
                Button(action: self.action) {
                    Text("reportMessage_report"~)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(FilledButton())
                .onGeometryChange(for: CGFloat.self) { proxy in
                    return proxy.size.height
                } action: { height in
                    self.height = height
                }
                .transition(.motion(.identity))
            } else {
                ReportSubmitMorph(isDone: self.phase == .done, diameter: self.height)
                    .transition(.motion(.identity))
            }
        }
        .frame(maxWidth: .infinity)
        .sensoryFeedback(.success, trigger: self.phase == .done)
    }
}


//MARK: - Morph -
private struct ReportSubmitMorph: View {

    let isDone: Bool
    let diameter: CGFloat

    var body: some View {
        Capsule()
            .fill(.tint)
            .overlay {
                Capsule()
                    .fill(.green)
                    .opacity(self.isDone ? 1 : 0)
            }
            .overlay {
                ZStack {
                    if !self.isDone {
                        ProgressView()
                            .tint(.white)
                            .transition(.motion(.scale(scale: ReportSubmitMotion.spinnerStartScale).combined(with: .opacity)))
                    }

                    Image(systemName: "checkmark")
                        .font(ReportSubmitMotion.checkFont)
                        .foregroundStyle(.white)
                        .writeOn(isShown: self.isDone, delay: ReportSubmitMotion.checkDelay, duration: ReportSubmitMotion.checkDuration)
                        .environment(\.layoutDirection, .leftToRight)
                        .accessibilityHidden(true)
                }
            }
            .frame(height: self.diameter)
            .collapseToCircle(diameter: self.diameter)
            .celebrate(isCelebrating: self.isDone, color: .green)
    }
}


//MARK: - Preview -
#Preview {
    VStack(spacing: 24) {
        ReportSubmitButton(phase: .idle, action: {})
        ReportSubmitButton(phase: .sending, action: {})
        ReportSubmitButton(phase: .done, action: {})
    }
    .padding()
}
