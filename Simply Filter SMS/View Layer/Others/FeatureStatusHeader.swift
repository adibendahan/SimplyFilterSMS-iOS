//
//  FeatureStatusHeader.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 21/11/2026.
//

import SwiftUI


//MARK: - View -
struct FeatureStatusHeader: View {

    @ScaledMetric(relativeTo: .largeTitle) private var iconSize: CGFloat = 76

    let feature: Feature
    let isOn: Bool
    let badgeTitle: StatusBadge.Title
    let badgeOnWidthSamples: [String]
    let badgeOffTitle: String
    let collapseProgress: CGFloat

    var body: some View {
        VStack(spacing: 6) {
            self.icon
                .font(.system(size: self.iconSize))
                .scrollCollapse(progress: self.collapseProgress)
                .padding(.bottom, 8)
                .accessibilityHidden(true)

            StatusBadge(isOn: self.isOn,
                        title: self.badgeTitle,
                        onWidthSamples: self.badgeOnWidthSamples,
                        offTitle: self.badgeOffTitle)
            .font(.headline)
            .padding(.bottom, 4)

            Text(.init(self.feature.description))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }


    //MARK: - Private -
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
