//
//  WhatsNewOrbitView.swift
//  Simply Filter SMS
//

import SwiftUI


struct WhatsNewOrbitView: View {
    let entries: [WhatsNewEntry]
    let hasAppeared: Bool
    let collapse: CGFloat

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @ScaledMetric(relativeTo: .largeTitle) private var logoSize: CGFloat = 92
    @ScaledMetric(relativeTo: .largeTitle) private var orbitRadius: CGFloat = 104
    @ScaledMetric(relativeTo: .largeTitle) private var satelliteSize: CGFloat = 44

    @State private var spinBoost: Double = 0
    @State private var logoBounce = false

    private let secondsPerRevolution: Double = 48
    private let secondsPerPulse: Double = 2.4

    var body: some View {
        TimelineView(.animation(paused: self.reduceMotion)) { context in
            let drift = self.driftAngle(at: context.date)
            let pulse = self.pulsePhase(at: context.date)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.18), style: StrokeStyle(lineWidth: 1, dash: [3, 6]))
                    .frame(width: self.orbitRadius * 2, height: self.orbitRadius * 2)
                    .scaleEffect((self.hasAppeared ? 1 : 0.4) * (1 - 0.75 * self.motionCollapse))
                    .opacity(self.hasAppeared ? 1 - self.motionCollapse : 0)
                    .animation(.spring(response: 0.9, dampingFraction: 0.8).delay(0.1), value: self.hasAppeared)

                ForEach(Array(self.entries.enumerated()), id: \.element) { index, entry in
                    self.satellite(entry, index: index, drift: drift, pulse: pulse)
                }

                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: self.logoSize, height: self.logoSize)
                    .clipShape(RoundedRectangle(cornerRadius: self.logoSize * 0.225, style: .continuous))
                    .shadow(color: Color.green.opacity(0.35 * (1 - self.motionCollapse)), radius: self.hasAppeared ? 24 : 0, y: 8)
                    .scaleEffect(self.logoScale)
                    .rotationEffect(.degrees(self.hasAppeared ? 0 : -12))
                    .animation(.spring(response: 0.55, dampingFraction: 0.55), value: self.hasAppeared)
                    .animation(.spring(response: 0.35, dampingFraction: 0.45), value: self.logoBounce)
                    .scaleEffect(1 - 0.45 * self.logoCollapse)
                    .opacity(1 - self.logoCollapse)
                    .blur(radius: 8 * self.logoCollapse)
                    .onTapGesture {
                        self.logoTapped()
                    }
            }
            .offset(y: self.orbitRadius * 0.7 * self.motionCollapse)
            .opacity(self.reduceMotion ? 1 - self.collapse : 1)
            .frame(height: self.orbitRadius * 2 + self.satelliteSize)
            .frame(maxWidth: .infinity)
        }
        .accessibilityHidden(true)
    }


    //MARK: - Private -
    private var motionCollapse: CGFloat {
        let result: CGFloat
        if self.reduceMotion {
            result = 0
        } else {
            result = self.collapse
        }
        return result
    }

    private var logoCollapse: CGFloat {
        return self.collapseStage(start: 0.45, length: 0.55)
    }

    private var logoScale: CGFloat {
        let result: CGFloat
        if !self.hasAppeared {
            result = 0.5
        } else if self.logoBounce {
            result = 1.08
        } else {
            result = 1
        }
        return result
    }

    private func collapseStage(start: CGFloat, length: CGFloat) -> CGFloat {
        let raw = (self.motionCollapse - start) / length
        return min(max(raw, 0), 1)
    }

    private func driftAngle(at date: Date) -> Double {
        guard !self.reduceMotion else { return 0 }
        let seconds = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: self.secondsPerRevolution)
        return seconds / self.secondsPerRevolution * 2 * .pi
    }

    private func pulsePhase(at date: Date) -> Double {
        guard !self.reduceMotion else { return 0 }
        let seconds = date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: self.secondsPerPulse)
        return seconds / self.secondsPerPulse
    }

    private func satellite(_ entry: WhatsNewEntry, index: Int, drift: Double, pulse: Double) -> some View {
        let count = Double(max(self.entries.count, 1))
        let baseAngle = Double(index) / count * 2 * .pi - .pi / 2
        let pull = self.collapseStage(start: 0.05 * CGFloat(index), length: 0.55)
        let swirl = Double(pull) * .pi * 0.75
        let angle = baseAngle + drift + self.spinBoost + swirl
        let radius = self.hasAppeared ? self.orbitRadius * (1 - pull) : 0
        let x = cos(angle) * radius
        let y = sin(angle) * radius
        let delay = 0.15 + 0.06 * Double(index)
        let emphasis: CGFloat = entry.isCurrent ? 1.18 : 0.92
        let haloOpacity = entry.isCurrent && !self.reduceMotion ? (1 - pulse) * 0.6 : 0

        return ZStack {
            Circle()
                .stroke(entry.color, lineWidth: 1.5)
                .scaleEffect(1 + pulse * 0.6)
                .opacity(haloOpacity)

            Circle()
                .fill(entry.color.opacity(entry.isCurrent ? 0.24 : 0.14))

            Image(systemName: entry.imageName)
                .resizable()
                .scaledToFit()
                .foregroundColor(entry.color)
                .frame(width: self.satelliteSize * 0.48 * entry.iconScale, height: self.satelliteSize * 0.48 * entry.iconScale)
        }
        .frame(width: self.satelliteSize, height: self.satelliteSize)
        .scaleEffect(self.hasAppeared ? emphasis * (1 - 0.7 * pull) : 0.2)
        .opacity(self.hasAppeared ? 1 - pull : 0)
        .offset(x: x, y: y)
        .animation(.spring(response: 0.75, dampingFraction: 0.62).delay(delay), value: self.hasAppeared)
    }

    private func logoTapped() {
        guard !self.reduceMotion else { return }
        withAnimation(.spring(response: 1.1, dampingFraction: 0.75)) {
            self.spinBoost += 2 * .pi
        }
        self.logoBounce = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            self.logoBounce = false
        }
    }
}
