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
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .center, spacing: 0) {
                    if let isExpanded = self.isExpanded {
                        self.chevron(isExpanded: isExpanded)
                    }
                    Text(self.communityList.name)
                        .font(.body.weight(.semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                self.infoLine
                    .padding(.leading, self.isExpanded == nil ? 0 : self.chevronColumnWidth)

                if self.isExpanded == nil, let description = self.communityList.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let isActive = self.isActive {
                Toggle(self.communityList.name, isOn: isActive)
                    .labelsHidden()
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder
    private func chevron(isExpanded: Binding<Bool>) -> some View {
        if self.communityList.description != nil {
            Button {
                isExpanded.wrappedValue.toggle()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(Color(UIColor.tertiaryLabel))
                    .rotationEffect(.degrees(isExpanded.wrappedValue ? 90 : 0))
                    .frame(width: self.chevronColumnWidth, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
        } else {
            Color.clear
                .frame(width: self.chevronColumnWidth, height: 1)
        }
    }

    private var infoLine: some View {
        HStack(spacing: 5) {
            if let localeLabel = self.communityList.localeLabel {
                Text(localeLabel)
                    .accessibilityLabel(self.communityList.localeName ?? localeLabel)
            }
            if self.communityList.localeLabel != nil, self.communityList.homepage != nil {
                Text("·")
                    .accessibilityHidden(true)
            }
            if let homepage = self.communityList.homepage {
                Link(homepage.displayHost, destination: homepage)
                    .buttonStyle(.borderless)
                    .foregroundStyle(.tint)
            }
        }
        .font(.caption)
        .foregroundColor(.secondary)
        .lineLimit(1)
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
        }
    }
}


//MARK: - Preview -
struct CommunityListRowView_Previews: PreviewProvider {
    static let communityList = CommunityListItem(url: "https://lists.example.com/sample.sfsfilters",
                                                 name: "Sample List",
                                                 description: "A sample list for previews.",
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
