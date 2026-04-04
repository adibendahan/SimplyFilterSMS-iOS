//
//  GlassPicker.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 03/04/2026.
//

import SwiftUI

private struct GlassPickerLabelStyle: LabelStyle {
    let isSelected: Bool

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
                .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            configuration.title
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
        }
    }
}

struct GlassPicker<T, Content: View>: View where T: CaseIterable & Identifiable & Equatable & Hashable, T.AllCases: RandomAccessCollection {
    @Binding var selection: T
    let content: (T) -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private var allCases: [T] { Array(T.allCases) }
    @Namespace private var chipNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(allCases) { option in
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.72)) {
                        selection = option
                    }
                } label: {
                    content(option)
                        .labelStyle(GlassPickerLabelStyle(isSelected: selection == option))
                        .foregroundStyle(selection == option ? Color.accentColor : Color.secondary)
                        .font(.footnote.weight(selection == option ? .semibold : .regular))
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
                    content(option).tag(option)
                }
            }
            .pickerStyle(.segmented)
        }
        .frame(height: 36)
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(LinearGradient(
                            colors: [.white.opacity(0.3), .white.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        ), lineWidth: 0.5)
                }
        )
    }

    private var chip: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(.regularMaterial)
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(LinearGradient(
                        colors: [.white.opacity(0.2), .white.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(LinearGradient(
                        colors: [.white.opacity(0.6), .white.opacity(0.15)],
                        startPoint: .top,
                        endPoint: .bottom
                    ), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.15), radius: 5, x: 0, y: 2)
    }
}
