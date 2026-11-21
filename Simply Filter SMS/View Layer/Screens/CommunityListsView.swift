//
//  CommunityListsView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 12/11/2026.
//

import SwiftUI


//MARK: - View -
struct CommunityListsView: View, ViewWithPersistentStoreReload {

    @ScaledMetric(relativeTo: .caption2) private var detailsIndent = CommunityListRow.chevronColumnBaseWidth
    @StateObject var model: ViewModel
    @State private var emptyStatePresence = ListEmptyStateView.Presence()
    @State private var headerCollapse: CGFloat = 0

    init(model: ViewModel) {
        _model = StateObject(wrappedValue: model)
        _emptyStatePresence = State(initialValue: ListEmptyStateView.Presence(isShown: model.userRowViewModels.isEmpty))
    }

    var body: some View {
        List {
            Section {
                FeatureStatusHeader(feature: .communityLists,
                                    isOn: self.model.activeListsCount > 0,
                                    badgeTitle: self.model.badgeTitle,
                                    badgeOnWidthSamples: self.model.badgeOnWidthSamples,
                                    badgeOffTitle: self.model.badgeOffTitle,
                                    collapseProgress: self.headerCollapse)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
            .listSectionSpacing(.compact)

            if !self.model.curatedRowViewModels.isEmpty {
                Section {
                    ForEach(self.model.curatedRowViewModels, id: \.id) { rowModel in
                        self.rows(for: rowModel)
                    }
                } header: {
                    Text("communityLists_featured"~)
                } footer: {
                    if self.isLastUpdatedUnderFeatured, let lastUpdatedFooter = self.model.lastUpdatedFooter {
                        self.footer(AttributedString(lastUpdatedFooter))
                    }
                } // Section
                .motionTransaction()
            }

            Section {
                ForEach(self.model.userRowViewModels, id: \.id) { rowModel in
                    self.rows(for: rowModel)
                }
                .onDelete(perform: self.model.removeCommunityLists)

                if self.emptyStatePresence.isShown {
                    ListEmptyStateView(kind: .communityLists)
                        .id(self.emptyStatePresence.appearance)
                }
            } header: {
                Text("communityLists_addedByYou"~)
            } footer: {
                self.footer(self.model.addedByYouFooter(includesLastUpdated: !self.isLastUpdatedUnderFeatured))
            } // Section
            .motionTransaction()

            Section {
                Button {
                    self.model.presentAddCommunityList()
                } label: {
                    Label("communityLists_subscribeFromURL"~, systemImage: "link.badge.plus")
                }
                .foregroundStyle(.primary)
                .accessibilityIdentifier(TestIdentifier.addCommunityListButton.rawValue)
            } // Section
        } // List
        .modifier(ListEmptyStateView.PresenceTracker(isEmpty: self.model.userRowViewModels.isEmpty, presence: $emptyStatePresence))
        .modifier(FeatureStatusHeader.CollapseTracker(progress: self.$headerCollapse))
        .contentMargins(.top, 8, for: .scrollContent)
        .listStyle(.insetGrouped)
        .navigationTitle("communityLists_title"~)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                communityListsTrailingMenu
            }
        }
        .environment(\.editMode, $model.editMode)
        .sheet(item: $model.addCommunityListViewModel) { vm in
            AddCommunityListView(model: vm)
                .inAppBrowser()
        }
        .onReceive(self.model.$addCommunityListViewModel) { vm in
            if vm == nil {
                self.model.refresh()
            }
        }
        .refreshable(action: self.model.refreshCommunityLists)
        .onAppear {
            self.model.startMonitoring()
        }
        .modifier(persistentStoreReload)
    }

    private var isLastUpdatedUnderFeatured: Bool {
        return self.emptyStatePresence.isActive && !self.model.curatedRowViewModels.isEmpty
    }

    private func footer(_ text: AttributedString) -> some View {
        return Text(text)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func rows(for rowModel: CommunityListRowView.ViewModel) -> some View {
        CommunityListRowView(model: rowModel, isExpanded: self.expansion(rowModel))

        if self.model.expandedCommunityListID == rowModel.id {
            CommunityListDetails(communityList: rowModel.communityList)
                .padding(.leading, self.detailsIndent)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 16, trailing: 20))
                .listRowSeparator(.hidden)
                .deleteDisabled(true)
        }
    }

    private func expansion(_ rowModel: CommunityListRowView.ViewModel) -> Binding<Bool> {
        Binding(
            get: { self.model.expandedCommunityListID == rowModel.id },
            set: { open in
                withMotionAnimation(.easeInOut) {
                    if open {
                        self.model.expandedCommunityListID = rowModel.id
                    } else if self.model.expandedCommunityListID == rowModel.id {
                        self.model.expandedCommunityListID = nil
                    }
                }
            }
        )
    }

    @ViewBuilder
    private var communityListsTrailingMenu: some View {
        if self.model.editMode.isEditing {
            EditButton()
        } else {
            Menu {
                if self.model.hasUserLists {
                    Button(action: {
                        withAnimation {
                            self.model.editMode = .active
                        }
                    }) {
                        Label("general_edit"~, systemImage: "pencil")
                    }
                }

                Link(destination: .communityListGuideURL) {
                    Label("communityLists_createList"~, systemImage: "hammer")
                }
                Link(destination: .communityListProposalURL) {
                    Label("communityLists_submitList"~, systemImage: "text.bubble")
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .tint(.primary)
            .accessibilityLabel("a11y_home_menuButton"~)
        }
    }
}


//MARK: - ViewModel -
extension CommunityListsView {

    class ViewModel: BaseViewModel, @unchecked Sendable, ObservableObject, PersistentStoreReloadRefreshing {
        @Published private(set) var rowViewModels: [CommunityListRowView.ViewModel] = []
        @Published var editMode: EditMode = .inactive
        @Published var expandedCommunityListID: String?
        @Published var addCommunityListViewModel: AddCommunityListView.ViewModel? = nil {
            didSet {
                let wasShown = oldValue != nil
                let isShown = self.addCommunityListViewModel != nil
                guard wasShown != isShown else { return }
                Log.debug("add community list sheet, shown: \(wasShown) → \(isShown)")
            }
        }
        private var didAddObservers = false

        override init(appManager: AppManagerProtocol = AppManager.shared) {
            super.init(appManager: appManager)
            self.updateRowViewModels()
        }

        func startMonitoring() {
            guard !self.didAddObservers else { return }
            self.didAddObservers = true

            NotificationCenter.default.addObserver(forName: .filterListsUpdated, object: nil, queue: .main) { [weak self] _ in
                withAnimation {
                    self?.refresh()
                }
            }
        }

        func refresh() {
            self.updateRowViewModels()
        }

        var activeListsCount: Int {
            return self.rowViewModels.filter(\.isActive).count
        }

        var headline: String {
            return String.localizedStringWithFormat("communityLists_active_count"~, self.activeListsCount)
        }

        var badgeTitle: StatusBadge.Title {
            return StatusBadge.Title(text: self.headline, count: self.activeListsCount)
        }

        var badgeOnWidthSamples: [String] {
            let sampleCounts = [1, max(self.rowViewModels.count, 1)]
            let samples = sampleCounts.map { String.localizedStringWithFormat("communityLists_active_count"~, $0) }
            return samples.uniqued()
        }

        var badgeOffTitle: String {
            return String.localizedStringWithFormat("communityLists_active_count"~, 0)
        }

        var lastUpdatedFooter: String? {
            guard let lastUpdated = self.appManager.filterListManager.filterListsLastUpdated else { return nil }
            return lastUpdated.lastUpdatedText + "."
        }

        func addedByYouFooter(includesLastUpdated: Bool) -> AttributedString {
            var guideLink = AttributedString("communityLists_createList"~)
            guideLink.link = .communityListGuideURL

            var proposalLink = AttributedString("communityLists_submitList"~)
            proposalLink.link = .communityListProposalURL

            var footer = AttributedString()
            if includesLastUpdated, let lastUpdatedFooter = self.lastUpdatedFooter {
                footer = AttributedString(lastUpdatedFooter + " ")
            }
            footer.append(guideLink)
            footer.append(AttributedString(" · "))
            footer.append(proposalLink)
            return footer
        }

        var curatedRowViewModels: [CommunityListRowView.ViewModel] {
            return self.rowViewModels.filter { $0.communityList.isCurated }
        }

        var userRowViewModels: [CommunityListRowView.ViewModel] {
            return self.rowViewModels.filter { !$0.communityList.isCurated }
        }

        var hasUserLists: Bool {
            return !self.userRowViewModels.isEmpty
        }

        func presentAddCommunityList() {
            self.addCommunityListViewModel = AddCommunityListView.ViewModel(appManager: self.appManager)
        }

        func removeCommunityLists(at offsets: IndexSet) {
            let userRowViewModels = self.userRowViewModels
            for index in offsets {
                let communityList = userRowViewModels[index].communityList
                self.appManager.filterListManager.removeCommunityList(communityList)
            }
            self.refresh()
            if !self.hasUserLists, self.editMode.isEditing {
                Log.debug("last user list removed → editing ended")
                self.editMode = .inactive
            }
        }

        @Sendable func refreshCommunityLists() async {
            Log.debug("pull to refresh")
            await self.appManager.filterListManager.refreshFilterLists()

            Task {
                DispatchQueue.main.async {
                    self.refresh()
                }
            }
        }

        private func updateRowViewModels() {
            let existingViewModels = Dictionary(uniqueKeysWithValues: self.rowViewModels.map({ ($0.id, $0) }))
            var updatedViewModels: [CommunityListRowView.ViewModel] = []

            for communityList in self.appManager.filterListManager.communityLists {
                if let existing = existingViewModels[communityList.id] {
                    existing.updateCommunityList(communityList)
                    updatedViewModels.append(existing)
                }
                else {
                    let vm = CommunityListRowView.ViewModel(
                        communityList: communityList,
                        onUpdate: { [weak self] in
                            self?.refresh()
                        },
                        appManager: self.appManager)
                    updatedViewModels.append(vm)
                }
            }

            self.rowViewModels = updatedViewModels
        }
    }
}


//MARK: - Preview -
struct CommunityListsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CommunityListsView(model: CommunityListsView.ViewModel(appManager: AppManager.previews))
        }
    }
}
