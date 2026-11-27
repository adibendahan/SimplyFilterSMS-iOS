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
        HStack(spacing: 4) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.footnote)
                    .accessibilityHidden(true)
            }
            Text(text)
                .font(.footnote)
                .fontWeight(.medium)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
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
                RoundedRectangle(cornerRadius: 8, style: .continuous)
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
            .padding(.vertical, showButtonShapes ? 4 : 0)
            .padding(.horizontal, showButtonShapes ? 8 : 0)
            .background {
                if showButtonShapes {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(.tint.opacity(0.12))
                }
            }
    }
}
