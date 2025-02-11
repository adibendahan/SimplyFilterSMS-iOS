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
    
    @ObservedObject var model: ViewModel
    
    var body: some View {
        List (selection: $model.selectedFilters) {
            Section {
                ForEach(self.model.filters, id: \.self) { filter in
                    FilterListRowView(model: FilterListRowView.ViewModel(
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
        .navigationBarItems(trailing: EditButton())
        .navigationBarItems(trailing: NavigationBarTrailingItem())
        .navigationTitle(self.model.filterType.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $model.sheetScreen) { } content: { sheetScreen in
            sheetScreen.build()
        }
        .onReceive(self.model.$sheetScreen, perform: { sheetScreen in
            if sheetScreen == nil {
                self.model.refresh()
            }
        })
        .environment(\.editMode, $model.editMode)
        .onTapGesture {
            hideKeyboard()
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
                        .foregroundColor(.red)
                })
        }
    }
    
    @ViewBuilder
    private func AddFilterButton() -> some View {
        
        if (self.model.filterType == .denyLanguage &&
            self.model.canBlockAnotherLanguage) ||
            self.model.filterType != .denyLanguage {
            
            Button(action: {
                switch self.model.filterType {
                case .deny:
                    self.model.sheetScreen = .addDenyFilter
                case .allow:
                    self.model.sheetScreen = .addAllowFilter
                case .denyLanguage:
                    self.model.sheetScreen = .addLanguageFilter
                }
            }) {
                HStack {
                    Spacer()
                    
                    switch self.model.filterType {
                    case .deny, .allow:
                        Image(systemName: "plus.message")
                            .imageScale(.large)
                            .font(.system(size: 20, weight: .bold))
                        
                        Text(self.model.filterType == .deny ? "addFilter_addFilter_deny"~ : "addFilter_addFilter_allow"~)
                            .font(.body)
                        
                    case .denyLanguage:
                        Image(systemName: "globe")
                            .imageScale(.large)
                            .font(.system(size: 20, weight: .bold))
                        
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
                switch self.model.filterType {
                case .deny:
                    self.model.sheetScreen = .addDenyFilter
                case .allow:
                    self.model.sheetScreen = .addAllowFilter
                case .denyLanguage:
                    self.model.sheetScreen = .addLanguageFilter
                }
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
