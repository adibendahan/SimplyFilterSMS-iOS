//
//  ReportSubmitCard.swift
//  Simply Filter SMS
//

import SwiftUI


// MARK: - Card

/// Frosted-glass card showing a spinning loader during submission and a
/// green-circle checkmark on success. Used in ReportMessageView and the
/// Reporting Extension.
struct ReportSubmitCard: View {

    let isDone: Bool
    let text: String?

    @State private var showText: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ReportSubmitAnimationView(isDone: isDone)
                .frame(width: 80, height: 80)

            if showText, let text {
                Text(text)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .transition(.scale(scale: 0.85).combined(with: .opacity))
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: showText)
            }
            Spacer()
        }
        .frame(width: 220, height: 220)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 8)
        .transition(.scale(scale: 0.88).combined(with: .opacity))
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isDone)
        .onChange(of: isDone) { done in
            guard done else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation {
                    showText = true
                }
            }
        }
    }
}


// MARK: - Animation

/// Two arcs spin during loading (SpinningView style).
/// On success:
///   - The inner arc fades out; the green filled circle springs in.
///   - The outer arc (same line) unwinds via trim.from 0→1 while the checkmark draws via trim 0→1.
///   - Stroke stays white throughout — no color snap.
private struct ReportSubmitAnimationView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let isDone: Bool

    // Outer arc
    @State private var circleEnd: CGFloat = 0.001
    @State private var rotationDegree: Angle = .degrees(-90)
    @State private var arcTrimFrom: CGFloat = 0   // sweeps 0→1 to unwind the arc on success

    // Inner arc
    @State private var smallCircleEnd: CGFloat = 1
    @State private var smallRotationDegree: Angle = .degrees(-30)
    @State private var innerArcOpacity: Double = 1

    // Success
    @State private var showFilledCircle: Bool = false
    @State private var checkTrim: CGFloat = 0

    @State private var isSpinning: Bool = false

    private let dur: Double = 1.35

    var body: some View {
        ZStack {
            // Inner arc
            Circle()
                .trim(from: 0, to: smallCircleEnd)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(smallRotationDegree)
                .frame(width: 30, height: 30)
                .opacity(innerArcOpacity)

            // Green filled circle — springs in on success, sits behind the outer arc
            if showFilledCircle {
                Circle()
                    .fill(Color.green)
                    .frame(width: 80, height: 80)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
            }

            // Outer arc — the same line as during loading.
            // arcTrimFrom sweeps 0→1 to unwind it as the checkmark draws.
            Circle()
                .trim(from: arcTrimFrom, to: circleEnd)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(rotationDegree)
                .frame(width: 80, height: 80)

            // Checkmark — draws simultaneously with the arc unwinding.
            TickShape()
                .trim(from: 0, to: checkTrim)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                .frame(width: 36, height: 36)
        }
        .onAppear {
            guard !reduceMotion else {
                showFilledCircle = true
                innerArcOpacity = 0
                checkTrim = 1
                arcTrimFrom = 1
                return
            }
            isSpinning = true
            animate()
        }
        .onChange(of: isDone) { done in
            guard done else { return }
            transitionToSuccess()
        }
    }

    // MARK: - Success transition

    private func transitionToSuccess() {
        isSpinning = false

        // Complete the outer arc and fade the inner arc simultaneously
        withAnimation(.easeOut(duration: 0.2)) {
            circleEnd = 1
            innerArcOpacity = 0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            // Green circle springs in
            withAnimation(.spring(response: 0.38, dampingFraction: 0.72)) {
                showFilledCircle = true
            }
            // The arc unwinds (trim.from 0→1) while the checkmark draws (trim 0→1).
            // Same duration, same easing: the line reshapes from circle to checkmark.
            withAnimation(.easeInOut(duration: 0.52)) {
                arcTrimFrom = 1
            }
            withAnimation(.easeInOut(duration: 0.52)) {
                checkTrim = 1
            }
        }
    }

    // MARK: - Spinner loop

    private func animate() {
        withAnimation(.easeOut(duration: dur)) { circleEnd = 1 }
        withAnimation(.easeOut(duration: dur * 1.1)) { rotationDegree = .degrees(365) }
        withAnimation(.easeOut(duration: dur * 0.85)) {
            smallCircleEnd = 0.001
            smallRotationDegree = .degrees(679)
        }

        Timer.scheduledTimer(withTimeInterval: dur * 0.7, repeats: false) { _ in
            guard isSpinning else { return }
            withAnimation(.easeIn(duration: dur * 0.4)) {
                smallRotationDegree = .degrees(825)
                rotationDegree = .degrees(375)
            }
        }

        Timer.scheduledTimer(withTimeInterval: dur, repeats: false) { _ in
            guard isSpinning else { return }
            withAnimation(.easeOut(duration: dur)) {
                rotationDegree = .degrees(990)
                circleEnd = 0.001
            }
            withAnimation(.linear(duration: dur * 0.8)) {
                smallCircleEnd = 1
                smallRotationDegree = .degrees(990)
            }
        }

        Timer.scheduledTimer(withTimeInterval: dur * 1.98, repeats: false) { _ in
            guard isSpinning else { return }
            reset()
            animate()
        }
    }

    private func reset() {
        rotationDegree = .degrees(-90)
        smallRotationDegree = .degrees(-30)
    }
}


// MARK: - Checkmark shape

/// Two-segment checkmark path.
private struct TickShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to:    CGPoint(x: rect.minX + rect.width * 0.15, y: rect.midY + rect.height * 0.05))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.43, y: rect.maxY - rect.height * 0.12))
        path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.05, y: rect.minY + rect.height * 0.15))
        return path
    }
}


// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.3).ignoresSafeArea()
        ReportSubmitCard(isDone: false, text: nil)
    }
}
