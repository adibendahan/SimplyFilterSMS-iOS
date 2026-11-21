//
//  FiltersView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/12/2021.
//

import SwiftUI
import NaturalLanguage


//MARK: - View -
struct FiltersView: View, ViewWithPersistentStoreReload {
    
    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>
    
    @Environment(\.isDebug)
    var isDebug
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme
    
    @ScaledMetric(relativeTo: .title3) private var addFilterIconSize: CGFloat = 20

    @StateObject var model: ViewModel
    @State private var dotFilterID: UUID? = nil
    @State private var emptyStatePresence = ListEmptyStateView.Presence()
    @FocusState private var focusedFilterID: UUID?

    init(model: ViewModel) {
        _model = StateObject(wrappedValue: model)
        _emptyStatePresence = State(initialValue: ListEmptyStateView.Presence(isShown: model.filters.isEmpty))
    }

    var body: some View {
        ScrollViewReader { proxy in
        List (selection: $model.selectedFilters) {
            Section {
                ForEach(self.model.regularRowViewModels, id: \.id) { rowModel in
                    FilterRowView(
                        dotFilterID: dotFilterID,
                        focusedFilterID: $focusedFilterID,
                        model: rowModel,
                        isOptionsCollapsed: model.isFilterOptionsCollapsed)
                    .environment(\.editMode, $model.editMode)
                    .id(rowModel.id)
                    .tag(rowModel.filter)
                }
                .onDelete {
                    self.model.deleteFilters(withOffsets: $0, rowViewModels: self.model.regularRowViewModels)
                }
                .deleteDisabled(self.model.editMode.isEditing)
            } header: {
                if !self.model.regularRowViewModels.isEmpty {
                    AdaptiveColumnHeader(
                        leading: self.model.filterType == .denyLanguage ? "general_lang"~ : "filterList_text"~,
                        trailing: self.model.filterType.supportsAdvancedOptions ? "filterList_options"~ : "filterList_folder"~,
                        trailingSecondary: false)
                }
            } footer: {
                if !self.emptyStatePresence.isActive && self.model.regexRowViewModels.isEmpty {
                    listFooter
                }
            }

            if self.emptyStatePresence.isShown {
                Section {
                    self.emptyState
                        .id(self.emptyStatePresence.appearance)
                }
            }

            if !self.model.regexRowViewModels.isEmpty {
                Section {
                    ForEach(self.model.regexRowViewModels, id: \.id) { rowModel in
                        FilterRowView(
                            dotFilterID: dotFilterID,
                            focusedFilterID: $focusedFilterID,
                            model: rowModel,
                            isOptionsCollapsed: model.isFilterOptionsCollapsed)
                        .environment(\.editMode, $model.editMode)
                        .id(rowModel.id)
                        .tag(rowModel.filter)
                    }
                    .onDelete {
                        self.model.deleteFilters(withOffsets: $0, rowViewModels: self.model.regexRowViewModels)
                    }
                    .deleteDisabled(self.model.editMode.isEditing)
                } header: {
                    Text("addFilter_match_regex"~)
                } footer: {
                    listFooter
                }
            }
        } // List
        .modifier(ListEmptyStateView.PresenceTracker(isEmpty: self.model.filters.isEmpty, presence: $emptyStatePresence))
        .listStyle(InsetGroupedListStyle())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationBarTrailingItem()
            }
            if #available(iOS 27.0, *) {
                ToolbarItem(placement: .topBarPinnedTrailing) {
                    filterListTrailingMenu
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    filterListTrailingMenu
                }
            }
        }
        .navigationTitle(self.model.filterType.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $model.sheetScreen) { } content: { sheetScreen in
            sheetScreen.build()
        }
        .sheet(item: $model.addFilterViewModel) { vm in
            AddFilterView(model: vm)
        }
        .sheet(item: $model.addLanguageViewModel) { vm in
            BlockLanguageView(model: vm)
        }
        .onReceive(self.model.$sheetScreen, perform: { sheetScreen in
            if sheetScreen == nil {
                self.model.refresh()
            }
        })
        .onReceive(self.model.$addFilterViewModel, perform: { vm in
            if vm == nil {
                self.model.refresh()
            }
        })
        .onReceive(self.model.$addLanguageViewModel, perform: { vm in
            if vm == nil {
                self.model.refresh()
            }
        })
        .environment(\.editMode, $model.editMode)
        .onTapGesture {
            focusedFilterID = nil
            hideKeyboard()
        }
        .onAppear {
            self.model.revealSearchFocus()
        }
        .onChange(of: model.newlyAddedFilter) { _, newFilter in
            guard let filter = newFilter, let id = filter.uuid else { return }
            dotFilterID = id
            withAnimation {
                proxy.scrollTo(id, anchor: .center)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                if dotFilterID == id { dotFilterID = nil }
            }
        }
        } // ScrollViewReader
        .modifier(persistentStoreReload)
    }

    @ViewBuilder
    private var listFooter: some View {
        VStack(spacing: 16) {
            Text(.init(self.model.footer))

            AddFilterButton()
        }
    }
    
    @ViewBuilder
    private func NavigationBarTrailingItem() -> some View {
        if self.model.editMode.isEditing && self.model.selectedFilters.count > 0 {
            Button(
                action: {
                    withAnimation {
                        self.model.deleteFilters(self.model.selectedFilters)
                        self.model.selectedFilters = Set()
                        self.model.refresh()
                    }
                },
                label: {
                    Text(String(format: "filterList_deleteFiltersCount"~, self.model.selectedFilters.count))
                })
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }

    @ViewBuilder
    private var filterListTrailingMenu: some View {
        if self.model.editMode.isEditing {
            EditButton()
        } else {
            Menu {
                Button(action: {
                    withAnimation {
                        self.model.editMode = .active
                    }
                }) {
                    Label("general_edit"~, systemImage: "pencil")
                }

                Button {
                    self.model.setFilterOptionsCollapsed(!self.model.isFilterOptionsCollapsed)
                } label: {
                    Label(
                        self.model.isFilterOptionsCollapsed
                            ? "filterList_menu_expandOptions"~
                            : "filterList_menu_collapseOptions"~,
                        systemImage: "slider.horizontal.3")
                }

                Button(action: {
                    self.model.showAddFilter()
                }) {
                    Label(self.model.filterType.addFilterTitle, systemImage: self.model.filterType.addFilterIconName)
                }
            } label: {
                Image(systemName: "ellipsis")
            }
            .tint(.primary)
            .accessibilityLabel("a11y_home_menuButton"~)
        }
    }
    
    private var emptyState: some View {
        return ListEmptyStateView(kind: .filterList(self.model.filterType), action: self.emptyStateAction)
    }

    private var emptyStateAction: ListEmptyStateView.Action? {
        guard self.model.canAddFilter else { return nil }
        return ListEmptyStateView.Action(
            title: self.model.filterType.addFilterTitle,
            iconName: self.model.filterType.addFilterIconName,
            testIdentifier: .addFilterButton,
            perform: self.model.showAddFilter)
    }

    @ViewBuilder
    private func AddFilterButton() -> some View {
        
        if self.model.canAddFilter {
            
            Button(action: {
                self.model.showAddFilter()
            }) {
                HStack {
                    Image(systemName: self.model.filterType.addFilterIconName)
                        .imageScale(.large)
                        .font(.system(size: addFilterIconSize, weight: .bold))
                    
                    Text(self.model.filterType.addFilterTitle)
                        .font(.body)
                }
            }
            .buttonStyle(AccessibleTextButtonStyle())
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 1)
            .highPriorityGesture(TapGesture()
                .onEnded({ _ in
                self.model.showAddFilter()
            }))
            .accessibilityIdentifier(TestIdentifier.addFilterButton.rawValue)
        }
        else {
            EmptyView()
        }
    }
}


//MARK: - ViewModel -
extension FiltersView {
    
    class ViewModel: BaseViewModel, ObservableObject, PersistentStoreReloadRefreshing {
        @Published private(set) var filters: [Filter]
        @Published private(set) var rowViewModels: [FilterRowView.ViewModel] = []
        @Published private(set) var filterType: FilterType
        @Published private(set) var isAllUnknownFilteringOn: Bool
        @Published private(set) var canBlockAnotherLanguage: Bool
        @Published private(set) var footer: String
        @Published var selectedFilters: Set<Filter> = Set()
        @Published var editMode: EditMode = .inactive
        @Published private(set) var isFilterOptionsCollapsed: Bool
        @Published var sheetScreen: Screen? = nil {
            didSet {
                guard oldValue != self.sheetScreen else { return }
                Log.debug("sheet changed, screen: \(oldValue) → \(self.sheetScreen)")
            }
        }
        @Published var addFilterViewModel: AddFilterView.ViewModel? = nil {
            didSet {
                let wasShown = oldValue != nil
                let isShown = self.addFilterViewModel != nil
                guard wasShown != isShown else { return }
                Log.debug("add filter sheet, shown: \(wasShown) → \(isShown)")
            }
        }
        @Published var addLanguageViewModel: BlockLanguageView.ViewModel? = nil {
            didSet {
                let wasShown = oldValue != nil
                let isShown = self.addLanguageViewModel != nil
                guard wasShown != isShown else { return }
                Log.debug("add language sheet, shown: \(wasShown) → \(isShown)")
            }
        }
        @Published private(set) var newlyAddedFilter: Filter? = nil

        var regularRowViewModels: [FilterRowView.ViewModel] {
            self.rowViewModels.filter({ $0.filterMatching != .regex })
        }
        var regexRowViewModels: [FilterRowView.ViewModel] {
            self.rowViewModels.filter({ $0.filterMatching == .regex })
        }
        
        init(filterType: FilterType,
             appManager: AppManagerProtocol = AppManager.shared) {
            
            self.filterType = filterType
            self.isFilterOptionsCollapsed = appManager.defaultsManager.isFilterOptionsCollapsed
            
            self.isAllUnknownFilteringOn = appManager.smartFilterManager.isSmartFilterActive(for: .allUnknown)
            self.canBlockAnotherLanguage = !appManager.persistenceManager.blockableLanguages().isEmpty
            
            switch filterType {
            case .deny:
                self.footer = "help_deny"~
            case .allow:
                self.footer = "help_allow"~
            case .denyLanguage:
                self.footer = "lang_how"~
            }
            
            let fetchedFilters = appManager.persistenceManager.fetchFilterRecords(for: filterType)
            self.filters = fetchedFilters.filter({ $0.filterType == filterType })
            
            super.init(appManager: appManager)
            self.updateRowViewModels()
        }

        func setFilterOptionsCollapsed(_ isCollapsed: Bool) {
            guard self.isFilterOptionsCollapsed != isCollapsed else { return }
            Log.debug("filter options, collapsed: \(self.isFilterOptionsCollapsed) → \(isCollapsed)")
            self.isFilterOptionsCollapsed = isCollapsed
            self.appManager.defaultsManager.isFilterOptionsCollapsed = isCollapsed
        }
        
        func refresh() {
            let fetchedFilters = self.appManager.persistenceManager.fetchFilterRecords(for: self.filterType)

            self.filters = fetchedFilters.filter({ $0.filterType == self.filterType })
            self.isAllUnknownFilteringOn = self.appManager.smartFilterManager.isSmartFilterActive(for: .allUnknown)
            self.canBlockAnotherLanguage = !self.appManager.persistenceManager.blockableLanguages().isEmpty
            self.updateRowViewModels()
        }

        private func updateRowViewModels() {
            let existingViewModels = Dictionary(uniqueKeysWithValues: self.rowViewModels.map({ ($0.id, $0) }))
            var updatedViewModels: [FilterRowView.ViewModel] = []

            for filter in self.filters {
                if let uuid = filter.uuid, let existing = existingViewModels[uuid] {
                    existing.updateFilter(filter)
                    updatedViewModels.append(existing)
                }
                else {
                    let vm = FilterRowView.ViewModel(
                        filter: filter,
                        onUpdate: { [weak self] animated in
                            if animated {
                                withAnimation { self?.refresh() }
                            }
                            else {
                                self?.refresh()
                            }
                        },
                        appManager: self.appManager)
                    updatedViewModels.append(vm)
                }
            }

            self.rowViewModels = updatedViewModels
        }

        var canAddFilter: Bool {
            return self.filterType != .denyLanguage || self.canBlockAnotherLanguage
        }

        func showAddFilter() {
            if self.filterType == .denyLanguage {
                let vm = BlockLanguageView.ViewModel(onAdded: { [weak self] filter in
                    self?.filterWasAdded(filter)
                })
                self.addLanguageViewModel = vm
                return
            }
            let vm = AddFilterView.ViewModel(filterType: self.filterType, onAdded: { [weak self] filter in
                self?.filterWasAdded(filter)
            })
            self.addFilterViewModel = vm
        }

        private func filterWasAdded(_ filter: Filter) {
            self.refresh()
            self.highlight(filter)
        }

        private func highlight(_ filter: Filter) {
            self.newlyAddedFilter = filter
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                if self?.newlyAddedFilter == filter {
                    self?.newlyAddedFilter = nil
                }
            }
        }
        
        func revealSearchFocus() {
            guard let uuid = self.appManager.searchManager.takeFocusedFilter() else { return }
            guard let filter = self.rowViewModels.first(where: { $0.filter.uuid == uuid })?.filter else {
                Log.debug("search focus not found, uuid: \(uuid) → skipped")
                return
            }
            self.highlight(filter)
        }

        func deleteFilters(withOffsets offsets: IndexSet, rowViewModels: [FilterRowView.ViewModel]) {
            let toDelete = Set(offsets.map { rowViewModels[$0].filter })
            self.deleteFilters(toDelete)
        }
        
        func deleteFilters(_ filters: Set<Filter>) {
            guard !filters.isEmpty else { return }
            self.appManager.persistenceManager.deleteFilters(filters)
            withAnimation {
                self.filters.removeAll { filters.contains($0) }
                self.selectedFilters.subtract(filters)
                self.updateRowViewModels()
            }
        }
    }
}


//MARK: - Preview -
struct FiltersView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FiltersView(model: FiltersView.ViewModel(filterType: .allow, appManager: AppManager.previews))
        }
    }
}

