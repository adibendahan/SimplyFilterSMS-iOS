//
//  FilterListView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/12/2021.
//

import SwiftUI
import NaturalLanguage


//MARK: - View -
struct FilterListView: View, ViewWithPersistentStoreReload {
    
    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>
    
    @Environment(\.isDebug)
    var isDebug
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme
    
    @ScaledMetric(relativeTo: .title3) private var addFilterIconSize: CGFloat = 20

    @StateObject var model: ViewModel
    @State private var dotFilterID: UUID? = nil
    @FocusState private var focusedFilterID: UUID?

    init(model: ViewModel) {
        _model = StateObject(wrappedValue: model)
    }

    var body: some View {
        ScrollViewReader { proxy in
        List (selection: $model.selectedFilters) {
            Section {
                ForEach(self.model.regularRowViewModels, id: \.id) { rowModel in
                    FilterListRowView(
                        dotFilterID: dotFilterID,
                        focusedFilterID: $focusedFilterID,
                        model: rowModel)
                    .environment(\.editMode, $model.editMode)
                    .id(rowModel.id)
                    .tag(rowModel.filter)
                }
                .onDelete {
                    self.model.deleteFilters(withOffsets: $0, rowViewModels: self.model.regularRowViewModels)
                }
                .deleteDisabled(self.model.editMode.isEditing)
            } header: {
                if self.model.regularFilters.count > 0 {
                    HStack {
                        Text(self.model.filterType == .denyLanguage ? "general_lang"~ : "filterList_text"~)

                        Spacer()

                        Text(self.model.filterType.supportsAdvancedOptions ? "filterList_options"~ : "filterList_folder"~)
                            .padding(.trailing, 8)
                    }
                }
            } footer: {
                if self.model.regexFilters.isEmpty {
                    VStack {
                        Text(.init(self.model.footer))

                        Spacer()

                        AddFilterButton()
                            .padding(.top, self.model.filters.count > 0 ? 0 : 120)
                    }
                }
            }

            if !self.model.regexFilters.isEmpty {
                Section {
                    ForEach(self.model.regexRowViewModels, id: \.id) { rowModel in
                        FilterListRowView(
                            dotFilterID: dotFilterID,
                            focusedFilterID: $focusedFilterID,
                            model: rowModel)
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
                    VStack {
                        Text(.init(self.model.footer))

                        Spacer()

                        AddFilterButton()
                            .padding(.top, self.model.filters.count > 0 ? 0 : 120)
                    }
                }
            }
        } // List
        .listStyle(InsetGroupedListStyle())
        .navigationBarItems(trailing: NavigationBarMenu())
        .navigationTitle(self.model.filterType.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $model.sheetScreen) { } content: { sheetScreen in
            sheetScreen.build()
        }
        .sheet(item: $model.addFilterViewModel) { vm in
            AddFilterView(model: vm)
        }
        .sheet(item: $model.addLanguageViewModel) { vm in
            LanguageListView(model: vm)
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
        .onChange(of: model.newlyAddedFilter) { newFilter in
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
    private func NavigationBarMenu() -> some View {
        HStack(spacing: 8) {
            NavigationBarTrailingItem()

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

                    Button(action: {
                        self.model.showAddFilter()
                    }) {
                        Label({
                            switch self.model.filterType {
                            case .deny, .allow:
                                return self.model.filterType == .deny ? ("addFilter_addFilter_deny"~) : ("addFilter_addFilter_allow"~)
                            case .denyLanguage:
                                return ("addFilter_addLanguage"~)
                            }
                        }(), systemImage: self.model.filterType == .denyLanguage ? "globe" : "plus.message")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .tint(.primary)
                .accessibilityLabel("a11y_home_menuButton"~)
            }
        }
    }
    
    @ViewBuilder
    private func AddFilterButton() -> some View {
        
        if (self.model.filterType == .denyLanguage &&
            self.model.canBlockAnotherLanguage) ||
            self.model.filterType != .denyLanguage {
            
            Button(action: {
                self.model.showAddFilter()
            }) {
                HStack {
                    Spacer()
                    
                    switch self.model.filterType {
                    case .deny, .allow:
                        Image(systemName: "plus.message")
                            .imageScale(.large)
                            .font(.system(size: addFilterIconSize, weight: .bold))
                        
                        Text(self.model.filterType == .deny ? "addFilter_addFilter_deny"~ : "addFilter_addFilter_allow"~)
                            .font(.body)
                        
                    case .denyLanguage:
                        Image(systemName: "globe")
                            .imageScale(.large)
                            .font(.system(size: addFilterIconSize, weight: .bold))
                        
                        Text("addFilter_addLanguage"~)
                            .font(.body)
                    }
                    
                    Spacer()
                }
                .contentShape(Rectangle())
                .frame(minWidth: 1, maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 1)
                .padding(.bottom, 40)
            }
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
extension FilterListView {
    
    class ViewModel: BaseViewModel, ObservableObject, PersistentStoreReloadRefreshing {
        @Published private(set) var filters: [Filter]
        @Published private(set) var rowViewModels: [FilterListRowView.ViewModel] = []
        @Published private(set) var filterType: FilterType
        @Published private(set) var isAllUnknownFilteringOn: Bool
        @Published private(set) var canBlockAnotherLanguage: Bool
        @Published private(set) var footer: String
        @Published var selectedFilters: Set<Filter> = Set()
        @Published var editMode: EditMode = .inactive
        @Published var sheetScreen: Screen? = nil
        @Published var addFilterViewModel: AddFilterView.ViewModel? = nil
        @Published var addLanguageViewModel: LanguageListView.ViewModel? = nil
        @Published private(set) var newlyAddedFilter: Filter? = nil

        var regularFilters: [Filter] { filters.filter { $0.filterMatching != .regex } }
        var regexFilters: [Filter] { filters.filter { $0.filterMatching == .regex } }
        var regularRowViewModels: [FilterListRowView.ViewModel] {
            self.rowViewModels.filter({ $0.filter.filterMatching != .regex })
        }
        var regexRowViewModels: [FilterListRowView.ViewModel] {
            self.rowViewModels.filter({ $0.filter.filterMatching == .regex })
        }
        
        init(filterType: FilterType,
             appManager: AppManagerProtocol = AppManager.shared) {
            
            self.filterType = filterType
            
            self.isAllUnknownFilteringOn = appManager.automaticFilterManager.automaticRuleState(for: .allUnknown)
            self.canBlockAnotherLanguage = !appManager.automaticFilterManager.languages(for: .blockLanguage).isEmpty
            
            switch filterType {
            case .deny:
                self.footer = "help_deny"~
            case .allow:
                self.footer = "help_allow"~
            case .denyLanguage:
                self.footer = "lang_how"~
            }
            
            let fetchedFilters = appManager.persistanceManager.fetchFilterRecords(for: filterType)
            self.filters = fetchedFilters.filter({ $0.filterType == filterType })
            
            super.init(appManager: appManager)
            self.updateRowViewModels()
        }
        
        func refresh() {
            let fetchedFilters = self.appManager.persistanceManager.fetchFilterRecords(for: self.filterType)

            self.filters = fetchedFilters.filter({ $0.filterType == self.filterType })
            self.isAllUnknownFilteringOn = self.appManager.automaticFilterManager.automaticRuleState(for: .allUnknown)
            self.canBlockAnotherLanguage = !self.appManager.automaticFilterManager.languages(for: .blockLanguage).isEmpty
            self.updateRowViewModels()
        }

        private func updateRowViewModels() {
            let existingViewModels = Dictionary(uniqueKeysWithValues: self.rowViewModels.map({ ($0.id, $0) }))
            var updatedViewModels: [FilterListRowView.ViewModel] = []

            for filter in self.filters {
                if let uuid = filter.uuid, let existing = existingViewModels[uuid] {
                    existing.updateFilter(filter)
                    updatedViewModels.append(existing)
                }
                else {
                    let vm = FilterListRowView.ViewModel(
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

        func showAddFilter() {
            if self.filterType == .denyLanguage {
                let vm = LanguageListView.ViewModel(mode: .blockLanguage, onAdded: { [weak self] filter in
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
            self.newlyAddedFilter = filter
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                if self?.newlyAddedFilter == filter {
                    self?.newlyAddedFilter = nil
                }
            }
        }
        
        func deleteFilters(withOffsets offsets: IndexSet, rowViewModels: [FilterListRowView.ViewModel]) {
            let toDelete = Set(offsets.map { rowViewModels[$0].filter })
            self.deleteFilters(toDelete)
        }
        
        func deleteFilters(_ filters: Set<Filter>) {
            guard !filters.isEmpty else { return }
            self.appManager.persistanceManager.deleteFilters(filters)
            withAnimation {
                self.filters.removeAll { filters.contains($0) }
                self.selectedFilters.subtract(filters)
                self.updateRowViewModels()
            }
        }
    }
}


//MARK: - Preview -
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FilterListView(model: FilterListView.ViewModel(filterType: .allow, appManager: AppManager.previews))
        }
    }
}

