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
    
    @StateObject var router: AppRouter
    @StateObject var model: ViewModel
    
    var body: some View {
        List (selection: $model.selectedFilters) {
            Section {
                ForEach(self.model.filters, id: \.self) { filter in
                    self.FilterView(filter)
                        .environment(\.editMode, $model.editMode)
                }
                .onDelete {
                    self.model.deleteFilters(withOffsets: $0, in: self.model.filters)
                }
            } header: {
                if self.model.filterType.supportsFolders && !self.model.filters.isEmpty {
                    HStack {
                        Text("filterList_text"~)
                        
                        Spacer()
                        
                        Text("filterList_folder"~)
                            .padding(.trailing, 8)
                    }
                }
                else {
                    Spacer()
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
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
        .onReceive(self.router.$sheetScreen, perform: { sheetScreen in
            if sheetScreen == nil {
                self.model.refresh()
            }
        })
        .environment(\.editMode, $model.editMode)
    }
    
    @ViewBuilder
    private func FilterView(_ filter: Filter) -> some View {
        
        if filter.filterType.supportsFolders {
            HStack (alignment: .center , spacing: 0) {
                
                if filter.filterType == .denyLanguage,
                   let filterText = filter.text,
                   let blockedLanguage = NLLanguage(filterText: filterText),
                   blockedLanguage != .undetermined,
                   let localizedName = blockedLanguage.localizedName {
                    
                    Text(localizedName)
                }
                else {
                    Text(filter.text ?? "general_null"~)
                }
                
                Spacer()
                
                Menu {
                    ForEach(DenyFolderType.allCases) { folder in
                        Button {
                            self.model.updateFilter(filter, denyFolder: folder)
                        } label: {
                            Label {
                                Text(folder.name)
                            } icon: {
                                Image(systemName: folder.iconName)
                            }
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: filter.denyFolderType.iconName)
                        
                        Text(filter.denyFolderType.name)
                            .font(.footnote)
                    }
                    .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                    .background(Color.secondary.opacity(0.1))
                    .foregroundColor(.red)
                    .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                } // Menu
            } // HStack
        }
        else {
            Text(filter.text ?? "general_null"~)
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
            
            Button {
                switch self.model.filterType {
                case .deny:
                    self.router.sheetScreen = .addDenyFilter
                case .allow:
                    self.router.sheetScreen = .addAllowFilter
                case .denyLanguage:
                    self.router.sheetScreen = .addLanguageFilter
                }
                
            } label: {
                Spacer()
                
                switch self.model.filterType {
                case .deny, .allow:
                    Image(systemName: "plus.message")
                        .imageScale(.large)
                        .font(.system(size: 20, weight: .bold))
                    
                    Text("addFilter_addFilter"~)
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
            .padding(.top, 1)
            .padding(.bottom, 40)
        }
        else {
            EmptyView()
        }
    }
}


//MARK: - ViewModel -
extension FilterListView {
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published var filters: [Filter]
        @Published var filterType: FilterType
        @Published var isAllUnknownFilteringOn: Bool
        @Published var canBlockAnotherLanguage: Bool
        @Published var footer: String
        @Published var selectedFilters: Set<Filter> = Set()
        @Published var editMode: EditMode = .inactive
        
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
        
        func updateFilter(_ filter: Filter, denyFolder: DenyFolderType) {
            self.appManager.persistanceManager.updateFilter(filter, denyFolder: denyFolder)
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
        let router = AppRouter(screen: .allowFilterList, appManager: AppManager.previews)
        NavigationView {
            AppRouterView(router: router)
        }
    }
}
