//
//  TipTierPicker.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 26/02/2026.
//
import SwiftUI


//MARK: - View -
struct TipTierPicker: View {

    struct Option: Identifiable {
        let tier: TipTier
        let displayPrice: String

        var id: TipTier {
            return self.tier
        }
    }

    let options: [Option]
    @Binding var selection: TipTier
    let isCompact: Bool
    let isRevealed: Bool

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    @Namespace private var chipNamespace


    var body: some View {
        HStack(spacing: Spacing.tight) {
            ForEach(Array(self.options.enumerated()), id: \.element.id) { index, option in
                self.segment(for: option)
                    .entrance(isShown: self.isRevealed, delay: SegmentMotion.delay(for: index), rise: SegmentMotion.rise, scale: SegmentMotion.startScale, blur: SegmentMotion.blur, animation: SegmentMotion.animation)
            }
        }
        .padding(Spacing.tight)
        .background(
            RoundedRectangle(cornerRadius: Radius.large, style: .continuous)
                .fill(Color.surfaceControl)
        )
        .sensoryFeedback(.selection, trigger: self.selection)
        .accessibilityRepresentation {
            Picker("tipJar_chooseATip"~, selection: self.$selection) {
                ForEach(self.options) { option in
                    Text("\(option.tier.displayName), \(option.displayPrice)")
                        .tag(option.tier)
                }
            }
            .pickerStyle(.segmented)
        }
    }


    //MARK: - Private -
    private func segment(for option: Option) -> some View {
        let isSelected = self.selection == option.tier
        let emojiFont: Font = self.isCompact ? .title2 : .largeTitle
        let verticalPadding = self.isCompact ? Spacing.item : Spacing.edge
        return Button {
            self.select(option.tier)
        } label: {
            VStack(spacing: self.isCompact ? Spacing.tight : Spacing.item) {
                Text(option.tier.emoji)
                    .font(emojiFont)
                    .accessibilityHidden(true)

                Text(option.displayPrice)
                    .font(self.isCompact ? .subheadline.weight(.semibold) : .headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.vertical, verticalPadding)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .background {
                if isSelected {
                    self.selectedChip
                }
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var selectedChip: some View {
        let chip = SelectedChip(cornerRadius: Radius.nested(in: Radius.large, inset: Spacing.tight))
        if self.reduceMotion {
            chip
                .transition(.opacity)
        } else {
            chip
                .matchedGeometryEffect(id: "chip", in: self.chipNamespace)
        }
    }

    private func select(_ tier: TipTier) {
        guard tier != self.selection else { return }
        let animation: Animation
        if self.reduceMotion {
            animation = ReducedMotion.fade
        } else {
            animation = SegmentMotion.selectionAnimation
        }
        withAnimation(animation) {
            self.selection = tier
        }
    }
}


//MARK: - Motion -
private enum SegmentMotion {
    static let rise: CGFloat = 8
    static let startScale: CGFloat = 0.92
    static let blur: CGFloat = 4
    static let animation = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let selectionAnimation = Animation.spring(response: 0.32, dampingFraction: 0.78)

    static func delay(for index: Int) -> Double {
        return Stagger.delay(for: index, step: 0.06, base: 0.1)
    }
}
