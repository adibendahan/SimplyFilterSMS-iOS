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

    @Environment(\.colorScheme)
    private var colorScheme

    @Namespace private var chipNamespace

    @ScaledMetric(relativeTo: .largeTitle) private var emojiSizeRegular: CGFloat = 38
    @ScaledMetric(relativeTo: .title2) private var emojiSizeCompact: CGFloat = 24
    @ScaledMetric(relativeTo: .body) private var segmentHeightRegular: CGFloat = 104
    @ScaledMetric(relativeTo: .body) private var segmentHeightCompact: CGFloat = 64

    var body: some View {
        HStack(spacing: 5) {
            ForEach(Array(self.options.enumerated()), id: \.element.id) { index, option in
                self.segment(for: option)
                    .entrance(isShown: self.isRevealed, delay: SegmentMotion.delay(for: index), rise: SegmentMotion.rise, scale: SegmentMotion.startScale, blur: SegmentMotion.blur, animation: SegmentMotion.animation)
            }
        }
        .padding(5)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.gray.opacity(0.12))
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
        let emojiSize = self.isCompact ? self.emojiSizeCompact : self.emojiSizeRegular
        let segmentHeight = self.isCompact ? self.segmentHeightCompact : self.segmentHeightRegular
        return Button {
            self.select(option.tier)
        } label: {
            VStack(spacing: self.isCompact ? 2 : 6) {
                Text(option.tier.emoji)
                    .font(.system(size: emojiSize))
                    .accessibilityHidden(true)

                Text(option.displayPrice)
                    .font(self.isCompact ? .subheadline.weight(.semibold) : .body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity, minHeight: segmentHeight)
            .contentShape(Rectangle())
            .background {
                if isSelected {
                    self.selectedChip
                }
            }
        }
        .buttonStyle(TipTierButtonStyle())
    }

    @ViewBuilder
    private var selectedChip: some View {
        let chip = RoundedRectangle(cornerRadius: 19, style: .continuous)
            .fill(self.colorScheme == .dark ? Color(.systemGray2) : Color(.systemBackground))
            .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
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


//MARK: - Button Style -
private struct TipTierButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect((self.reduceMotion || !configuration.isPressed) ? 1.0 : 0.95)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
