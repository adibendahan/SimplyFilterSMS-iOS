//
//  ButtonStyles.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 02/01/2022.
//

import SwiftUI

struct FilledButton: ButtonStyle {
    
    @Environment(\.isEnabled)
    private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        configuration
            .label
            .foregroundColor(configuration.isPressed ? .gray : .white)
            .padding()
            .background(isEnabled ? AnyShapeStyle(.tint) : AnyShapeStyle(.gray))
            .cornerRadius(8)
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
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
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

/// Plain text buttons; filled pill when Show Button Shapes is on.
struct AccessibleTextButtonStyle: ButtonStyle {
    @Environment(\.accessibilityShowButtonShapes) private var showButtonShapes
    var compact: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.tint)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.vertical, showButtonShapes ? (compact ? 4 : 10) : 0)
            .padding(.horizontal, showButtonShapes ? (compact ? 8 : 16) : 0)
            .background {
                if showButtonShapes {
                    RoundedRectangle(cornerRadius: compact ? 8 : 10, style: .continuous)
                        .fill(.tint.opacity(0.12))
                }
            }
    }
}
