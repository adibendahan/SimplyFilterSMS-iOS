//
//  ButtonStyles.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 02/01/2022.
//

import SwiftUI

struct FilledButton: PrimitiveButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        Button(configuration)
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
    }
}

struct FilterBadge: View {
    let text: String
    let color: Color
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: Spacing.tight) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.label)
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(.label)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, Spacing.item)
        .padding(.vertical, Spacing.tight)
        .background(color.opacity(Opacity.tintFill))
        .clipShape(Capsule())
        .accessibilityElement(children: .combine)
    }
}

struct OutlineButton: ButtonStyle {
    
    @Environment(\.isEnabled)
    private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundStyle(configuration.isPressed ? AnyShapeStyle(.gray) : AnyShapeStyle(.tint))
            .padding()
            .background(
                RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                    .stroke(.tint)
            )
    }
}

struct AccessibleTextButtonStyle: ButtonStyle {
    @Environment(\.accessibilityShowButtonShapes) private var showButtonShapes

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.tint)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.vertical, showButtonShapes ? Spacing.tight : 0)
            .padding(.horizontal, showButtonShapes ? Spacing.item : 0)
            .background {
                if showButtonShapes {
                    RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                        .fill(.tint.opacity(Opacity.tintFill))
                }
            }
    }
}
