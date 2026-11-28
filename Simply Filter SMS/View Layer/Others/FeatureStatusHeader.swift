//
//  FeatureStatusHeader.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 21/11/2026.
//

import SwiftUI


//MARK: - View -
struct FeatureStatusHeader: View {

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @ScaledMetric(relativeTo: .largeTitle) private var iconSizeRegular: CGFloat = IconSize.header
    @ScaledMetric(relativeTo: .title2) private var iconSizeCompact: CGFloat = IconSize.headerLandscape

    let feature: Feature
    let isOn: Bool
    let badgeTitle: StatusBadge.Title
    let badgeOnWidthSamples: [String]
    let badgeOffTitle: String
    let collapseProgress: CGFloat

    var body: some View {
        VStack(spacing: Spacing.tight) {
            self.icon
                .font(.system(size: self.iconSize))
                .scrollCollapse(progress: self.collapseProgress)
                .padding(.bottom, Spacing.item)
                .accessibilityHidden(true)

            StatusBadge(isOn: self.isOn,
                        title: self.badgeTitle,
                        onWidthSamples: self.badgeOnWidthSamples,
                        offTitle: self.badgeOffTitle)
            .font(.emphasis)
            .padding(.bottom, Spacing.tight)

            Text(.init(self.feature.description))
                .font(.description)
                .foregroundStyle(.primary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }


    //MARK: - Private -
    private var iconSize: CGFloat {
        return self.verticalSizeClass == .compact ? self.iconSizeCompact : self.iconSizeRegular
    }

    @ViewBuilder
    private var icon: some View {
        switch self.feature {
        case .aiFiltering:
            AIFilteringShieldIcon(isGlinting: self.isOn)
        case .communityLists:
            CommunityListsIcon(isPulsing: self.isOn)
        }
    }
}


//MARK: - Feature -
extension FeatureStatusHeader {
    enum Feature {
        case aiFiltering, communityLists

        var description: String {
            switch self {
            case .aiFiltering:
                return "autoFilter_description"~
            case .communityLists:
                return "communityLists_description"~
            }
        }
    }
}


//MARK: - Collapse -
extension FeatureStatusHeader {
    struct CollapseTracker: ViewModifier {
        @ScaledMetric(relativeTo: .largeTitle) private var distance: CGFloat = 120
        @Binding var progress: CGFloat

        private let bottomRoom: CGFloat = 50

        func body(content: Content) -> some View {
            content
                .contentMargins(.bottom, self.bottomRoom, for: .scrollContent)
                .onScrollProgress(distance: self.distance, progress: self.$progress)
        }
    }
}
