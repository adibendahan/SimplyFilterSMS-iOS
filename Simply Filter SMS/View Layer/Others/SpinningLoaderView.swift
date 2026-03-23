//
//  SpinningLoaderView.swift
//  Simply Filter SMS
//
//  Adapted from Shubham0812/SwiftUI-Animations (SpinningView).
//  Two arcs — a large outer and a small inner — that alternate
//  expanding and collapsing for a continuous looping effect.
//

import SwiftUI

struct SpinningLoaderView: View {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var circleEnd: CGFloat = 0.001
    @State private var rotationDegree: Angle = .degrees(-90)
    @State private var smallerCircleEnd: CGFloat = 1
    @State private var smallerRotationDegree: Angle = .degrees(-30)

    private let animationDuration: Double = 1.35

    var body: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: circleEnd)
                .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(rotationDegree)
                .frame(width: 80, height: 80)

            Circle()
                .trim(from: 0, to: smallerCircleEnd)
                .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .opacity(0.9)
                .rotationEffect(smallerRotationDegree)
                .frame(width: 30, height: 30)
        }
        .onAppear {
            guard !reduceMotion else { return }
            animate()
        }
    }

    // MARK: - Animation

    private func animate() {
        withAnimation(.easeOut(duration: animationDuration)) {
            circleEnd = 1
        }
        withAnimation(.easeOut(duration: animationDuration * 1.1)) {
            rotationDegree = .degrees(365)
        }
        withAnimation(.easeOut(duration: animationDuration * 0.85)) {
            smallerCircleEnd = 0.001
            smallerRotationDegree = .degrees(679)
        }

        Timer.scheduledTimer(withTimeInterval: animationDuration * 0.7, repeats: false) { _ in
            withAnimation(.easeIn(duration: animationDuration * 0.4)) {
                smallerRotationDegree = .degrees(825)
                rotationDegree = .degrees(375)
            }
        }

        Timer.scheduledTimer(withTimeInterval: animationDuration, repeats: false) { _ in
            withAnimation(.easeOut(duration: animationDuration)) {
                rotationDegree = .degrees(990)
                circleEnd = 0.001
            }
            withAnimation(.linear(duration: animationDuration * 0.8)) {
                smallerCircleEnd = 1
                smallerRotationDegree = .degrees(990)
            }
        }

        Timer.scheduledTimer(withTimeInterval: animationDuration * 1.98, repeats: false) { _ in
            reset()
            animate()
        }
    }

    private func reset() {
        rotationDegree = .degrees(-90)
        smallerRotationDegree = .degrees(-30)
    }
}


#Preview {
    SpinningLoaderView()
        .foregroundColor(.accentColor)
}
