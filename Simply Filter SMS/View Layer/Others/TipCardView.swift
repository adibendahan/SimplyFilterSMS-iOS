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

    @ScaledMetric(relativeTo: .title2) private var emojiSizeRegular: CGFloat = 28
    @ScaledMetric(relativeTo: .body) private var emojiSizeCompact: CGFloat = 20
    @ScaledMetric(relativeTo: .subheadline) private var nameSizeRegular: CGFloat = 15
    @ScaledMetric(relativeTo: .caption) private var nameSizeCompact: CGFloat = 13
    @ScaledMetric(relativeTo: .caption2) private var descSizeRegular: CGFloat = 11
    @ScaledMetric(relativeTo: .caption2) private var descSizeCompact: CGFloat = 10
    @ScaledMetric(relativeTo: .caption2) private var descHeightRegular: CGFloat = 30
    @ScaledMetric(relativeTo: .caption2) private var descHeightCompact: CGFloat = 14

    var body: some View {
        Button(action: action) {
            VStack(spacing: isCompact ? 4 : 8) {
                Text(tier.emoji)
                    .font(.system(size: isCompact ? emojiSizeCompact : emojiSizeRegular))
                    .accessibilityHidden(true)

                Text(tier.displayName)
                    .font(.system(size: isCompact ? nameSizeCompact : nameSizeRegular, weight: .semibold))
                    .foregroundColor(.primary)

                Text(tier.tierDescription)
                    .font(.system(size: isCompact ? descSizeCompact : descSizeRegular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(height: isCompact ? descHeightCompact : descHeightRegular, alignment: .center)

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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect((reduceMotion || !configuration.isPressed) ? 1.0 : 0.95)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

