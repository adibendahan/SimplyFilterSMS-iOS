//
//  TipCardView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 26/02/2026.
//
import SwiftUI

struct TipCardView: View {
    let tier: TipTier
    let displayPrice: String
    let isDisabled: Bool
    let isPurchasing: Bool
    let isCompact: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: isCompact ? 4 : 8) {
                Text(tier.emoji)
                    .font(.system(size: isCompact ? 20 : 28))

                Text(tier.displayName)
                    .font(.system(size: isCompact ? 13 : 15, weight: .semibold))
                    .foregroundColor(.primary)

                Text(tier.tierDescription)
                    .font(.system(size: isCompact ? 10 : 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(height: isCompact ? 14 : 30, alignment: .center)

                if isPurchasing {
                    ProgressView()
                        .padding(.horizontal, 10)
                        .padding(.vertical, isCompact ? 2 : 4)
                } else {
                    Text(displayPrice)
                        .font(isCompact ? .caption.bold() : .subheadline.bold())
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, isCompact ? 2 : 4)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(.vertical, isCompact ? 8 : 16)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(.gray).opacity(0.1))
            )
        }
        .buttonStyle(TipCardButtonStyle())
        .disabled(isDisabled)
    }
}


//MARK: - Button Style -
private struct TipCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

