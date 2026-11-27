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
    @ScaledMetric(relativeTo: .title2) private var circleSize: CGFloat = 48

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left: numbered circle + connector
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isActive ? Color.primary : Color(.tertiarySystemFill))
                        .frame(width: self.circleSize, height: self.circleSize)
                        .scaleEffect(isActive || reduceMotion ? 1.0 : 0.85)
                    Text("\(step.stepNumber)")
                        .font(.title2.bold())
                        .foregroundStyle(isActive ? Color(UIColor.systemBackground) : Color.secondary)
                }
                .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.65), value: isActive)
                .accessibilityHidden(true)

                if !step.isLast {
                    Rectangle()
                        .fill(Color.primary.opacity(0.2))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 2)
                }
            }

            // Right: title + description, toggle at trailing
            AdaptiveRow(stackedTrailingAlignment: .trailing, compactAlignment: .top) {
                EmptyView()
            } content: {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        if step.showsAppIcon {
                            AppIconView()
                                .accessibilityHidden(true)
                        } else if let symbolName = step.symbolName {
                            Image(systemName: symbolName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(step.symbolColor.map { AnyShapeStyle($0) } ?? AnyShapeStyle(.tint))
                                .accessibilityHidden(true)
                        }
                        Text(step.title)
                            .font(.headline)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Text(step.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .if(needsStackedLayout) { content in
                            content.fixedSize(horizontal: false, vertical: true)
                        }
                        .if(!needsStackedLayout) { content in
                            content
                                .lineLimit(2)
                                .minimumScaleFactor(0.7)
                                .frame(height: 40, alignment: .topLeading)
                        }
                }
                .opacity(isActive ? 1.0 : 0.35)
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
            .padding(.bottom, 12)
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
    @ScaledMetric(relativeTo: .subheadline) private var iconSize: CGFloat = 15

    var body: some View {
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String],
           let name = files.last,
           let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .frame(width: self.iconSize, height: self.iconSize)
                .clipShape(RoundedRectangle(cornerRadius: self.iconSize * 0.225, style: .continuous))
        }
    }
}
