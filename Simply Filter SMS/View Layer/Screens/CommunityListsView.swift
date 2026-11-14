//
//  CommunityListsView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 12/11/2026.
//

import SwiftUI


//MARK: - View -
struct CommunityListsView: View, ViewWithPersistentStoreReload {

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .caption2) private var descriptionIndent = CommunityListRow.chevronColumnBaseWidth
    @StateObject var model: ViewModel

    init(model: ViewModel) {
        _model = StateObject(wrappedValue: model)
    }

    var body: some View {
        List {
            Section {
                ForEach(self.model.rowViewModels, id: \.id) { rowModel in
                    CommunityListRowView(model: rowModel, isExpanded: self.expansion(rowModel))
                        .deleteDisabled(rowModel.communityList.isCurated)

                    if self.model.expandedCommunityListID == rowModel.id, let description = rowModel.communityList.description {
                        Text(description)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.leading, self.descriptionIndent)
                            .listRowInsets(EdgeInsets(top: -14, leading: 20, bottom: 12, trailing: 20))
                            .listRowSeparator(.hidden)
                            .deleteDisabled(true)
                    }
                }
                .onDelete(perform: self.model.removeCommunityLists)

                if self.model.rowViewModels.isEmpty {
                    ContentUnavailableView("communityLists_empty"~, systemImage: "person.3")
                }
            } // Section
            .transaction { transaction in
                if self.reduceMotion {
                    transaction.animation = nil
                }
            }

            Section {
                Button {
                    self.model.presentAddCommunityList()
                } label: {
                    Label("communityLists_subscribeFromURL"~, systemImage: "link.badge.plus")
                }
                .foregroundStyle(.primary)
                .accessibilityIdentifier(TestIdentifier.addCommunityListButton.rawValue)
            } footer: {
                Text(self.model.footer)
                    .multilineTextAlignment(.leading)
            } // Section
        } // List
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

    private func expansion(_ rowModel: CommunityListRowView.ViewModel) -> Binding<Bool> {
        Binding(
            get: { self.model.expandedCommunityListID == rowModel.id },
            set: { open in
                withAnimation(self.reduceMotion ? nil : .easeInOut) {
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
                Image(systemName: "ellipsis.circle")
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

        var footer: AttributedString {
            var guideLink = AttributedString("communityLists_createList"~)
            guideLink.link = .communityListGuideURL

            var proposalLink = AttributedString("communityLists_submitList"~)
            proposalLink.link = .communityListProposalURL

            var footerText = "communityLists_footer"~ + " "
            if let lastUpdated = self.appManager.filterListManager.filterListsLastUpdated {
                footerText = lastUpdated.lastUpdatedText + ". " + footerText
            }

            var footer = AttributedString(footerText)
            footer.append(guideLink)
            footer.append(AttributedString(" · "))
            footer.append(proposalLink)
            return footer
        }

        var hasUserLists: Bool {
            return self.rowViewModels.contains { !$0.communityList.isCurated }
        }

        func presentAddCommunityList() {
            self.addCommunityListViewModel = AddCommunityListView.ViewModel(appManager: self.appManager)
        }

        func removeCommunityLists(at offsets: IndexSet) {
            for index in offsets {
                let communityList = self.rowViewModels[index].communityList
                guard !communityList.isCurated else {
                    Log.debug("curated community list can't be removed, url: \(communityList.url) → skipped")
                    continue
                }
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
