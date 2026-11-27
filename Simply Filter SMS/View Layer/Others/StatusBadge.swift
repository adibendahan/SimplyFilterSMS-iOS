//
//  StatusBadge.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 21/11/2026.
//

import SwiftUI


//MARK: - View -
struct StatusBadge: View {

    let isOn: Bool
    let title: Title
    let onWidthSamples: [String]
    let offTitle: String
    var onColor: Color = .green

    var body: some View {
        AnimatedValue(self.isOn, animation: StatusBadgeMotion.room) { roomIsOn in
            Label {
                ZStack(alignment: .leading) {
                    ForEach(self.widthSamples(roomIsOn: roomIsOn), id: \.self) { sample in
                        Text(sample)
                            .hidden()
                    }
                }
                .overlay(alignment: .leading) {
                    FadeSwap(self.state, isSwap: StatusBadgeMotion.isTextSwap, timing: StatusBadgeMotion.text) { shownState in
                        self.titleText(shownState.title)
                    }
                }
                .monospacedDigit()
            } icon: {
                AnimatedValue(self.isOn, animation: StatusBadgeMotion.icon) { iconIsOn in
                    StatusBadgeIcon(isOn: iconIsOn)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .modifier(StatusBadgeModifier(isOn: roomIsOn, onColor: self.onColor))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(self.title.text)
    }


    //MARK: - Private -
    private var state: BadgeState {
        return BadgeState(isOn: self.isOn, title: self.title)
    }

    private func widthSamples(roomIsOn: Bool) -> [String] {
        let result: [String]
        if roomIsOn {
            result = self.onWidthSamples
        } else {
            result = [self.offTitle]
        }
        return result
    }

    private func titleText(_ title: Title) -> some View {
        return HStack(spacing: 0) {
            Text(title.prefix)
            Text(title.number)
                .contentTransition(.numericText(value: Double(title.count)))
            Text(title.suffix)
                .contentTransition(.numericText())
        }
        .fixedSize()
    }
}

extension StatusBadge {
    fileprivate struct BadgeState: Equatable {
        let isOn: Bool
        let title: Title
    }
}


//MARK: - Line -
struct StatusLine: View {

    let isOn: Bool
    let text: String
    var onColor: Color = .green

    @ScaledMetric(relativeTo: .caption2) private var iconSize: CGFloat = 8

    var body: some View {
        let statusColor = self.isOn ? self.onColor : Color.secondary
        let statusText = self.isOn ? "autoFilter_ON"~ : "autoFilter_OFF"~
        let shownText = self.isOn ? self.text : ""
        let spokenParts = [statusText, shownText].filter { !$0.isEmpty }

        HStack(alignment: .center, spacing: 4) {
            StatusBadgeIcon(isOn: self.isOn)
                .font(.system(size: self.iconSize))
                .foregroundStyle(statusColor)
            self.label(statusText: statusText, shownText: shownText, statusColor: statusColor)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.caption2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenParts.joined(separator: ", "))
    }

    private func label(statusText: String, shownText: String, statusColor: Color) -> Text {
        let result: Text
        if shownText.isEmpty {
            result = Text(statusText)
                .fontWeight(.semibold)
                .foregroundStyle(statusColor)
        }
        else {
            result = Text(shownText)
        }
        return result
    }
}


//MARK: - Icon -
struct StatusBadgeIcon: View {
    let isOn: Bool

    var body: some View {
        Image(systemName: "circle")
            .hidden()
            .overlay {
                GeometryReader { proxy in
                    let size = min(proxy.size.width, proxy.size.height)
                    let lineWidth = size * IconGeometry.lineRatio
                    let checkProgress: CGFloat = self.isOn ? 1 : 0

                    ZStack {
                        Circle()
                            .inset(by: lineWidth / 2)
                            .stroke(style: self.dottedRingStyle(size: size, lineWidth: lineWidth))
                            .opacity(self.isOn ? 0 : 1)
                        Circle()
                            .inset(by: lineWidth / 2)
                            .stroke(lineWidth: lineWidth)
                            .opacity(self.isOn ? 1 : 0)
                        Circle()
                            .opacity(self.isOn ? 1 : 0)
                        StatusBadgeCheck()
                            .trim(from: 0, to: checkProgress)
                            .stroke(style: StrokeStyle(lineWidth: lineWidth * IconGeometry.checkWeightRatio, lineCap: .round, lineJoin: .round))
                            .blendMode(.destinationOut)
                    }
                    .compositingGroup()
                    .environment(\.layoutDirection, .leftToRight)
                    .frame(width: size, height: size)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
                }
            }
            .accessibilityHidden(true)
    }

    private func dottedRingStyle(size: CGFloat, lineWidth: CGFloat) -> StrokeStyle {
        let circumference = CGFloat.pi * (size - lineWidth)
        let segment = circumference / IconGeometry.ringDashCount
        let dash = segment * IconGeometry.ringDashFill
        return StrokeStyle(lineWidth: lineWidth, lineCap: .round, dash: [dash, segment - dash])
    }
}

private enum IconGeometry {
    static let lineRatio: CGFloat = 0.075
    static let ringDashCount: CGFloat = 12
    static let ringDashFill: CGFloat = 0.42
    static let checkWeightRatio: CGFloat = 1.4
}

private struct StatusBadgeCheck: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + rect.width * 0.29, y: rect.minY + rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.44, y: rect.minY + rect.height * 0.67))
        path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.71, y: rect.minY + rect.height * 0.36))
        return path
    }
}


//MARK: - Style -
private struct StatusBadgeModifier: ViewModifier {
    let isOn: Bool
    let onColor: Color

    func body(content: Content) -> some View {
        let badgeColor = self.isOn ? self.onColor : Color.secondary
        let backgroundColor = self.isOn ? self.onColor.opacity(0.12) : Color(.tertiarySystemFill)

        content
            .foregroundStyle(badgeColor)
            .background(backgroundColor, in: Capsule())
    }
}


//MARK: - Title -
extension StatusBadge {
    struct Title: Equatable {
        let prefix: String
        let number: String
        let suffix: String
        let count: Int

        var text: String {
            return self.prefix + self.number + self.suffix
        }

        init(text: String, count: Int) {
            let number = String.localizedStringWithFormat("%ld", count)
            if let numberRange = text.range(of: number) {
                self.prefix = String(text[..<numberRange.lowerBound])
                self.number = number
                self.suffix = String(text[numberRange.upperBound...])
            }
            else {
                self.prefix = text
                self.number = ""
                self.suffix = ""
            }
            self.count = count
        }
    }
}


//MARK: - Motion -
private enum StatusBadgeMotion {
    static func icon(from wasOn: Bool, to isOn: Bool) -> Animation {
        let duration = isOn ? 0.25 : 0.45
        return Animation.smooth(duration: duration)
    }

    static func room(from wasOn: Bool, to isOn: Bool) -> Animation {
        return Animation.smooth(duration: 0.35)
    }

    static func isTextSwap(from oldState: StatusBadge.BadgeState, to newState: StatusBadge.BadgeState) -> Bool {
        return oldState.isOn != newState.isOn
    }

    static func text(from oldState: StatusBadge.BadgeState, to newState: StatusBadge.BadgeState) -> FadeSwapTiming {
        let result: FadeSwapTiming
        if newState.isOn {
            result = FadeSwapTiming(fadeOut: .easeOut(duration: 0.1), fadeIn: .easeOut(duration: 0.3), update: .snappy)
        } else {
            result = FadeSwapTiming(fadeOut: .easeOut(duration: 0.08), fadeIn: .easeOut(duration: 0.12), update: .snappy)
        }
        return result
    }
}
