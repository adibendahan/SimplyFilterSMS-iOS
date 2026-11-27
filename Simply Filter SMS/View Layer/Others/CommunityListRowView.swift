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

    static let chevronColumnBaseWidth: CGFloat = 18

    @ScaledMetric(relativeTo: .caption2) private var chevronColumnWidth = CommunityListRow.chevronColumnBaseWidth

    let communityList: CommunityListItem
    var isExpanded: Binding<Bool>? = nil
    var isActive: Binding<Bool>? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .center, spacing: 0) {
                        if let isExpanded = self.isExpanded {
                            self.chevron(isExpanded: isExpanded)
                        }
                        Text(self.communityList.name)
                            .font(.body)
                            .foregroundColor(.primary)
                            .adaptiveLineLimit(1)
                            .minimumScaleFactor(0.8)

                        if let ruleCountText = self.ruleCountText {
                            Text("(\(ruleCountText))")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .fixedSize()
                                .padding(.leading, 4)
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
        .padding(.vertical, 4)
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
        HStack(spacing: 4) {
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
        .foregroundColor(.secondary)
        .adaptiveLineLimit(1)
    }
}

struct CommunityListDetails: View {

    @Environment(\.layoutDirection) private var layoutDirection
    @ScaledMetric(relativeTo: .footnote) private var gitHubIconSize: CGFloat = 11

    let communityList: CommunityListItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let description = self.communityList.description {
                Text(description)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .environment(\.layoutDirection, self.descriptionLayoutDirection)
            }
            if let homepage = self.communityList.homepage {
                Link(destination: homepage) {
                    HStack(alignment: .center, spacing: 4) {
                        if homepage.isGitHubLink {
                            Image("GitHub")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: self.gitHubIconSize, height: self.gitHubIconSize)
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
        .font(.footnote)
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
