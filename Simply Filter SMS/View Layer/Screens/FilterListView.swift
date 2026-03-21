//
//  FilterListView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/12/2021.
//

import SwiftUI
import CoreData
import NaturalLanguage


//MARK: - View -
struct FilterListView: View {
    
    @Environment(\.presentationMode)
    var presentationMode: Binding<PresentationMode>
    
    @Environment(\.isDebug)
    var isDebug
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme
    
    @ScaledMetric(relativeTo: .title3) private var addFilterIconSize: CGFloat = 20

    @StateObject var model: ViewModel
    @State private var dotFilterID: NSManagedObjectID? = nil

    init(model: ViewModel) {
        _model = StateObject(wrappedValue: model)
    }

    var body: some View {
        ScrollViewReader { proxy in
        List (selection: $model.selectedFilters) {
            Section {
                ForEach(self.model.filters, id: \.self) { filter in
                    FilterListRowView(
                        filterObjectID: filter.objectID,
                        dotFilterID: dotFilterID,
                        model: FilterListRowView.ViewModel(
                            filter: filter,
                            onUpdate: { animated in
                                if animated {
                                    withAnimation { self.model.refresh() }
                                }
                                else {
                                    self.model.refresh()
                                }
                            },
                            appManager: self.model.appManager))
                    .environment(\.editMode, $model.editMode)
                    .id(filter.objectID)
                }
                .onDelete {
                    self.model.deleteFilters(withOffsets: $0, in: self.model.filters)
                }
            } header: {
                if self.model.filters.count > 0 {
                    HStack {
                        Text(self.model.filterType == .denyLanguage ? "general_lang"~ : "filterList_text"~)
                        
                        Spacer()
                        
                        Text(self.model.filterType.supportsAdvancedOptions ? "filterList_options"~ : "filterList_folder"~)
                            .padding(.trailing, 8)
                    }
                }
            } footer: {
                VStack {
                    Text(.init(self.model.footer))
                    
                    Spacer()
                    
                    AddFilterButton()
                        .padding(.top, self.model.filters.count > 0 ? 0 : 120)
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
            hideKeyboard()
        }
        .onChange(of: model.newlyAddedFilter) { newFilter in
            guard let filter = newFilter else { return }
            dotFilterID = filter.objectID
            withAnimation {
                proxy.scrollTo(filter.objectID, anchor: .center)
            }
            let targetID = filter.objectID
            DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                if dotFilterID == targetID { dotFilterID = nil }
            }
        }
        } // ScrollViewReader
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
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published private(set) var filters: [Filter]
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
        }
        
        func refresh() {
            let fetchedFilters = self.appManager.persistanceManager.fetchFilterRecords(for: self.filterType)

            self.filters = fetchedFilters.filter({ $0.filterType == self.filterType })
            self.isAllUnknownFilteringOn = self.appManager.automaticFilterManager.automaticRuleState(for: .allUnknown)
            self.canBlockAnotherLanguage = !self.appManager.automaticFilterManager.languages(for: .blockLanguage).isEmpty
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
        
        func deleteFilters(withOffsets offsets: IndexSet, in filters: [Filter]) {
            self.appManager.persistanceManager.deleteFilters(withOffsets: offsets, in: filters)
            self.refresh()
        }
        
        func deleteFilters(_ filters: Set<Filter>) {
            self.appManager.persistanceManager.deleteFilters(filters)
            self.refresh()
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

