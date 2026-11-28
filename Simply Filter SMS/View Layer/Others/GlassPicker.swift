//
//  GlassPicker.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 03/04/2026.
//

import SwiftUI
import UIKit

struct SelectedChip: View {
    let cornerRadius: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: self.cornerRadius, style: .continuous)
        if #available(iOS 26.0, *) {
            Color.clear
                .glassEffect(.regular, in: shape)
        } else {
            shape
                .fill(Color(UIColor { $0.userInterfaceStyle == .dark ? .systemGray2 : .systemBackground }))
        }
    }
}

private struct GlassPickerLabelStyle: LabelStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: Spacing.tight) {
            configuration.icon
                .foregroundStyle(isSelected ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            configuration.title
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
        }
    }
}

struct GlassPicker<T, Content: View>: View where T: CaseIterable & Identifiable & Equatable & Hashable & TestIdentifiable, T.AllCases: RandomAccessCollection {
    @Binding var selection: T
    let content: (T) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var allCases: [T] { Array(T.allCases) }
    @Namespace private var chipNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(allCases) { option in
                Button {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    withAnimation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.72)) {
                        selection = option
                    }
                } label: {
                    content(option)
                        .labelStyle(GlassPickerLabelStyle(isSelected: selection == option))
                        .foregroundStyle(selection == option ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
                        .font(.label.weight(selection == option ? .semibold : .regular))
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                        .animation(nil, value: selection)
                        .background {
                            if selection == option {
                                chip
                                    .matchedGeometryEffect(id: "chip", in: chipNamespace)
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .background(
            HorizontalDragRecognizer(selection: $selection, allCases: allCases, reduceMotion: reduceMotion)
        )
        .accessibilityRepresentation {
            Picker("", selection: $selection) {
                ForEach(allCases) { option in
                    content(option)
                        .tag(option)
                        .accessibilityIdentifier(option.testIdentifier.rawValue)
                }
            }
            .pickerStyle(.segmented)
        }
        .frame(height: SystemMetric.minTapTarget - Spacing.tight * 2)
        .padding(Spacing.tight)
        .background(
            RoundedRectangle(cornerRadius: Radius.medium, style: .continuous)
                .fill(Color.surfaceControl)
        )
    }

    private var chip: some View {
        SelectedChip(cornerRadius: Radius.nested(in: Radius.medium, inset: Spacing.tight))
    }
}
