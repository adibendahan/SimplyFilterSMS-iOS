//
//  EnableExtensionStepView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 07/03/2026.
//

import SwiftUI

private let kEnableExtensionToggleDelay: UInt64 = 400_000_000 // delay before toggle animates on after step activates

struct EnableExtensionStepView: View {
    let step: EnableExtensionStep
    let isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var toggleOn = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Left: numbered circle + connector
            VStack(spacing: 0) {
                ZStack {
                    Circle()
                        .fill(isActive ? Color.primary : Color(UIColor.systemGray3))
                        .frame(width: 48, height: 48)
                        .scaleEffect(isActive || reduceMotion ? 1.0 : 0.85)
                    Text("\(step.stepNumber)")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color(UIColor.systemBackground))
                }
                .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(response: 0.4, dampingFraction: 0.65), value: isActive)
                .accessibilityHidden(true)

                if !step.isLast {
                    Rectangle()
                        .fill(Color.primary.opacity(0.2))
                        .frame(width: 2)
                        .frame(maxHeight: .infinity)
                        .padding(.vertical, 3)
                }
            }

            // Right: title + description, toggle at trailing
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        if step.showsAppIcon {
                            AppIconView()
                                .accessibilityHidden(true)
                        } else if let symbolName = step.symbolName,
                                  let symbolColor = step.symbolColor {
                            Image(systemName: symbolName)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(symbolColor)
                                .accessibilityHidden(true)
                        }
                        Text(step.title)
                            .font(.headline)
                    }
                    Text(step.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .frame(height: 40, alignment: .topLeading)
                }
                .opacity(isActive ? 1.0 : 0.35)
                .animation(.easeInOut(duration: 0.3), value: isActive)

                Spacer()

                if step.isToggle {
                    Toggle("", isOn: $toggleOn)
                        .labelsHidden()
                        .controlSize(.mini)
                        .scaleEffect(0.7)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
            .padding(.bottom, 14)
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
    var body: some View {
        if let icons = Bundle.main.infoDictionary?["CFBundleIcons"] as? [String: Any],
           let primary = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let files = primary["CFBundleIconFiles"] as? [String],
           let name = files.last,
           let uiImage = UIImage(named: name) {
            Image(uiImage: uiImage)
                .resizable()
                .frame(width: 15, height: 15)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        }
    }
}
