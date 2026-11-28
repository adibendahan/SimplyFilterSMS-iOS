//
//  EnableExtensionStepView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 07/03/2026.
//

import SwiftUI

private let kEnableExtensionToggleDelay: UInt64 = 400_000_000 // delay before toggle animates on after step activates

struct EnableExtensionStepView: View {
    let step: any EnableExtensionStepProtocol
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.needsStackedLayout) private var needsStackedLayout
    @State private var toggleOn = false
    @ScaledMetric(relativeTo: .title2) private var circleSize: CGFloat = LineHeight.heading + Spacing.item * 2

    var body: some View {
        HStack(alignment: .top, spacing: Spacing.edge) {
            // Left: numbered circle + connector
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isActive ? Color.primary : Color.surfaceControl)
                        .frame(width: self.circleSize, height: self.circleSize)
                        .scaleEffect(isActive || reduceMotion ? 1.0 : 0.85)
                    Text("\(step.stepNumber)")
                        .font(.heading)
                        .foregroundStyle(isActive ? Color(UIColor.systemBackground) : Color.secondary)
                }
                .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.65), value: isActive)
                .accessibilityHidden(true)

                if !step.isLast {
                    Rectangle()
                        .fill(Color(.separator))
                        .frame(width: SystemMetric.separatorWidth)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, Spacing.tight)
                }
            }

            // Right: title + description, toggle at trailing
            AdaptiveRow(stackedTrailingAlignment: .trailing, compactAlignment: .top) {
                EmptyView()
            } content: {
                VStack(alignment: .leading, spacing: Spacing.tight) {
                    HStack(spacing: Spacing.tight) {
                        if step.showsAppIcon {
                            AppIconView()
                                .accessibilityHidden(true)
                        } else if let symbolName = step.symbolName {
                            Image(systemName: symbolName)
                                .font(.description.weight(.semibold))
                                .foregroundStyle(step.symbolColor.map { AnyShapeStyle($0) } ?? AnyShapeStyle(.tint))
                                .accessibilityHidden(true)
                        }
                        Text(step.title)
                            .font(.emphasis)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(step.description)
                        .font(.description)
                        .foregroundStyle(.primary)
                        .if(needsStackedLayout) { content in
                            content.fixedSize(horizontal: false, vertical: true)
                        }
                        .if(!needsStackedLayout) { content in
                            content
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                                .frame(height: LineHeight.description * 2, alignment: .topLeading)
                        }
                }
                .opacity(isActive ? 1.0 : Opacity.dim)
                .animation(.easeInOut(duration: 0.3), value: isActive)
            } trailing: {
                if step.isToggle {
                    Toggle("", isOn: $toggleOn)
                        .labelsHidden()
                        .controlSize(.mini)
                        .scaleEffect(0.7)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .padding(.bottom, Spacing.edge)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(format: "a11y_enableExtension_stepLabel"~, step.stepNumber, step.title, step.description))
        .task(id: isActive) {
            guard step.isToggle else { return }
            if isActive {
                try? await Task.sleep(nanoseconds: kEnableExtensionToggleDelay)
                withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.5, dampingFraction: 0.7)) {
                    toggleOn = true
                }
            } else {
                withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.8)) {
                    toggleOn = false
                }
            }
        }
    }
}

private struct AppIconView: View {
    @ScaledMetric(relativeTo: .subheadline) private var iconSize: CGFloat = TextSize.description

    var body: some View {
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String],
           let name = files.last,
           let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .frame(width: self.iconSize, height: self.iconSize)
                .clipShape(RoundedRectangle(cornerRadius: Radius.appIcon(side: self.iconSize), style: .continuous))
        }
    }
}
