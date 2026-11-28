//
//  CommunityListRowView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 13/11/2026.
//

import SwiftUI


//MARK: - View -
struct CommunityListRowView: View {

    @ObservedObject var model: ViewModel
    let isExpanded: Binding<Bool>

    var body: some View {
        CommunityListRow(communityList: self.model.communityList,
                         isExpanded: self.isExpanded,
                         isActive: Binding(
                            get: { self.model.isActive },
                            set: { self.model.updateCommunityList(isActive: $0) }
                         ))
    }
}

struct CommunityListRow: View {

    static let chevronColumnBaseWidth: CGFloat = IconSize.column

    @ScaledMetric(relativeTo: .caption2) private var chevronColumnWidth = CommunityListRow.chevronColumnBaseWidth

    let communityList: CommunityListItem
    var isExpanded: Binding<Bool>? = nil
    var isActive: Binding<Bool>? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.item) {
            HStack(alignment: .center, spacing: Spacing.item) {
                VStack(alignment: .leading, spacing: Spacing.item) {
                    HStack(alignment: .center, spacing: 0) {
                        if let isExpanded = self.isExpanded {
                            self.chevron(isExpanded: isExpanded)
                        }
                        Text(self.communityList.name)
                            .font(.body)
                            .foregroundColor(.text)
                            .adaptiveLineLimit(1)
                            .minimumScaleFactor(0.8)

                        if let ruleCountText = self.ruleCountText {
                            Text("(\(ruleCountText))")
                                .font(.label)
                                .foregroundColor(.textSecondary)
                                .lineLimit(1)
                                .fixedSize()
                                .padding(.leading, Spacing.tight)
                                .accessibilityLabel(ruleCountText)
                        }
                    }

                    self.infoLine
                        .padding(.leading, self.isExpanded == nil ? 0 : self.chevronColumnWidth)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let isActive = self.isActive {
                    Toggle(self.communityList.name, isOn: isActive)
                        .labelsHidden()
                        .accessibilityIdentifier(TestIdentifier.communityListToggle.rawValue)
                }
            }

            if self.isExpanded == nil {
                CommunityListDetails(communityList: self.communityList)
            }
        }
        .padding(.vertical, Spacing.tight)
    }

    private var ruleCountText: String? {
        guard let ruleCount = self.communityList.ruleCount, ruleCount > 0 else { return nil }
        return String.localizedStringWithFormat("autoFilter_ruleCount"~, ruleCount)
    }

    @ViewBuilder
    private func chevron(isExpanded: Binding<Bool>) -> some View {
        Button {
            isExpanded.wrappedValue.toggle()
        } label: {
            Image(systemName: "chevron.right")
                .font(.caption2.weight(.bold))
                .foregroundColor(Color(UIColor.tertiaryLabel))
                .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                .flipsForRightToLeftLayoutDirection(true)
                .frame(width: self.chevronColumnWidth, alignment: .leading)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(isExpanded.wrappedValue ? "a11y_communityLists_hideDescription"~ : "a11y_communityLists_showDescription"~)
        .accessibilityIdentifier(TestIdentifier.communityListExpandButton.rawValue)
    }

    private var infoLine: some View {
        HStack(spacing: Spacing.tight) {
            if let localeLabel = self.communityList.localeLabel {
                Text(localeLabel)
                    .fixedSize()
                    .accessibilityLabel(self.communityList.localeName ?? localeLabel)
            }
            if self.communityList.localeLabel != nil, self.communityList.author != nil {
                Text("·")
                    .accessibilityHidden(true)
            }
            if let author = self.communityList.author {
                Text(String(format: "communityLists_byAuthor"~, author))
                    .minimumScaleFactor(0.8)
            }
        }
        .font(.caption)
        .foregroundColor(.textSecondary)
        .adaptiveLineLimit(1)
    }
}

struct CommunityListDetails: View {

    @Environment(\.layoutDirection) private var layoutDirection

    let communityList: CommunityListItem

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.item) {
            if let description = self.communityList.description {
                Text(description)
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .environment(\.layoutDirection, self.descriptionLayoutDirection)
            }
            if let homepage = self.communityList.homepage {
                Link(destination: homepage) {
                    HStack(alignment: .center, spacing: Spacing.tight) {
                        if homepage.isGitHubLink {
                            Image("logo.github")
                                .foregroundStyle(Color.text)
                                .accessibilityHidden(true)
                        }
                        Text(homepage.displayLink)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.tint)
            }
        }
        .font(.label)
    }

    private var descriptionLayoutDirection: LayoutDirection {
        guard let language = self.communityList.locale?.language.languageCode else { return self.layoutDirection }
        let direction: LayoutDirection = language.isRightToLeft ? .rightToLeft : .leftToRight
        return direction
    }
}


//MARK: - ViewModel -
extension CommunityListRowView {

    class ViewModel: BaseViewModel, ObservableObject {
        let id: String
        @Published private(set) var communityList: CommunityListItem
        @Published private(set) var isActive: Bool
        private let onUpdate: (() -> ())?

        init(communityList: CommunityListItem,
             onUpdate: (() -> ())? = nil,
             appManager: AppManagerProtocol = AppManager.shared) {
            self.id = communityList.id
            self.communityList = communityList
            self.isActive = communityList.isActive
            self.onUpdate = onUpdate
            super.init(appManager: appManager)
        }

        func updateCommunityList(_ communityList: CommunityListItem) {
            self.communityList = communityList
            self.isActive = communityList.isActive
        }

        func updateCommunityList(isActive: Bool) {
            self.appManager.filterListManager.setCommunityListActive(self.communityList, value: isActive)
            self.onUpdate?()
            if isActive {
                self.appManager.flowManager.offerStayReachable()
            }
        }
    }
}


//MARK: - Preview -
struct CommunityListRowView_Previews: PreviewProvider {
    static let communityList = CommunityListItem(url: "https://lists.example.com/sample.sfsfilters",
                                                 name: "Sample List",
                                                 description: "A sample list for previews.",
                                                 author: "Jane Doe",
                                                 homepage: URL(string: "https://lists.example.com"),
                                                 locale: Locale(identifier: "en-US"),
                                                 cacheSection: nil,
                                                 isActive: true,
                                                 isCurated: true)

    static var previews: some View {
        List {
            CommunityListRowView(model: CommunityListRowView.ViewModel(communityList: communityList, appManager: AppManager.previews),
                                 isExpanded: .constant(true))
            CommunityListRow(communityList: communityList)
        }
        .listStyle(.insetGrouped)
    }
}
