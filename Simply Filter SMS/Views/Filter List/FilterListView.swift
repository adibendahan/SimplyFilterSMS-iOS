//
//  FilterListView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/12/2021.
//

import SwiftUI
import CoreData
import NaturalLanguage

struct FilterListView: View {
    
    @Environment(\.isPreview)
    var isPreview
    
    @Environment(\.isDebug)
    var isDebug
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme

    @StateObject var model: FilterListViewModel
    
    @State private var isPresentingFullScreenWelcome = false
    @State private var selectedFilters: Set<Filter> = Set()
    @State private var editMode: EditMode = .inactive
    @State private var presentedSheet: FilterListSheetView? = nil

    var body: some View {
        NavigationView {
            ZStack (alignment: .bottom) {
                List (selection: $selectedFilters) {
                    
                    if !self.model.isEmpty {
                        ForEach(FilterType.allCases.sorted(by: { $0.sortIndex < $1.sortIndex }), id: \.self) { filterType in
                            
                            if let sectionFilters = self.model.filters[filterType], sectionFilters.count > 0 {
                                Section {
                                    ForEach(sectionFilters, id: \.self) { filter in
                                        self.makeRow(for: filter)
                                            .environment(\.editMode, self.$editMode)
                                    }
                                    .onDelete {
                                        self.model.deleteFilters(withOffsets: $0, in: sectionFilters)
                                    }
                                } header: {
                                    HStack {
                                        Text(filterType.name)
                                        
                                        if filterType.supportsFolders {
                                            Spacer()
                                            
                                            Text("filterList_folder"~)
                                        }
                                    }
                                } footer: {
                                    switch filterType {
                                    case .deny:
                                        AddFilterButton()
                                        
                                    case .denyLanguage:
                                        if (self.model.filters[.deny] ?? []).count == 0 {
                                            AddFilterButton()
                                        }
                                        else {
                                            EmptyView()
                                        }
                                        
                                    case .allow:
                                        if (self.model.filters[.deny] ?? []).count == 0 && (self.model.filters[.denyLanguage] ?? []).count == 0 {
                                            AddFilterButton()
                                        }
                                        else {
                                            EmptyView()
                                        }
                                    }
                                }
                            }
                        } // ForEach
                    }
                    else { // When filters list is empty:
                        Section {
                            
                        } footer: {
                            AddFilterButton()
                                .padding(.top, 120)
                        }
                    }
                    
                } // List
                .listStyle(InsetGroupedListStyle())
                .navigationBarItems(leading: EditButton())
                .navigationBarItems(trailing: NavigationBarItemTrailing())
                .navigationTitle(self.model.title)
                .sheet(item: $presentedSheet) { // onDismiss:
                    self.presentedSheet = nil
                    self.model.fetchFilters()
                } content: { presentedSheet in
                    switch (presentedSheet) {
                    case .addFilter:
                        AddFilterView()
                    case .about:
                        AboutView()
                    case .help:
                        let model = HelpViewModel()
                        HelpView(model: model)
                    case .addLanguageFilter:
                        let model = LanguageListViewModel(viewType: .blockLanguage)
                        LanguageListView(model: model)
                    }
                }
                .fullScreenCover(isPresented: $isPresentingFullScreenWelcome, onDismiss: { }, content: {
                    EnableExtensionView(model: EnableExtensionViewModel(showWelcome: true))
                })
                .background(Color.listBackgroundColor(for: colorScheme))
                .onAppear() {
                    
                    if !isPreview && self.model.isAppFirstRun {
                        self.isPresentingFullScreenWelcome = true
                    }
                }
                .environment(\.editMode, $editMode)
                
                FooterView()
                    .onTapGesture {
                        self.presentedSheet = .about
                    }
            } // ZStack
        } // NavigationView
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear {
            self.model.fetchFilters()
        }
    }
    
    @ViewBuilder
    private func makeRow(for filter: Filter) -> some View {
        
        if filter.filterType.supportsFolders {
            HStack (alignment: .center , spacing: 0) {
                
                if filter.filterType == .denyLanguage,
                   let filterText = filter.text,
                   let blockedLanguage = NLLanguage(filterText: filterText),
                   blockedLanguage != .undetermined,
                   let localizedName = Locale.current.localizedString(forIdentifier: blockedLanguage.rawValue) {
                    
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
                }
            } // HStack
        }
        else {
            Text(filter.text ?? "general_null"~)
        }
    }
    
    @ViewBuilder
    private func NavigationBarItemTrailing() -> some View {
        if editMode.isEditing && selectedFilters.count > 0 {
            Button(
                role: .destructive,
                action: {
                    withAnimation {
                        self.model.deleteFilters(selectedFilters)
                        self.selectedFilters = Set()
                        self.model.fetchFilters()
                    }
                },
                label: {
                    Text(String(format: "filterList_deleteFiltersCount"~, selectedFilters.count))
                        .foregroundColor(.red)
            })
        }
        else {
            MenuView()
                .onAppear {
                    self.selectedFilters = Set()
                }
        }
    }
    
    private func AddFilterButton() -> some View {
        Button {
            presentedSheet = .addFilter
        } label: {
            Spacer()
            
            Image(systemName: "plus.message")
                .imageScale(.large)
                .font(.system(size: 20, weight: .bold))
            
            Text("addFilter_addFilter"~)
                .font(.body)
            
            Spacer()
        }
        .padding(.top, 1)
        .padding(.bottom, 40)
    }
    
    private func MenuView() -> some View {
        Menu {
            if isDebug && self.model.isEmpty {
                Button {
                    self.model.loadDebugData()
                } label: {
                    Label("filterList_menu_debug"~, systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }
            
            Button {
                presentedSheet = .addFilter
            } label: {
                Label("addFilter_addFilter"~, systemImage: "plus.message")
            }
            
            Button {
                presentedSheet = .addLanguageFilter
            } label: {
                Label("filterList_menu_filterLanguage"~, systemImage: "globe")
            }
            
            Button {
                presentedSheet = .help
            } label: {
                Label("filterList_menu_enableExtension"~, systemImage: "questionmark.circle")
            }
            
            Button {
                presentedSheet = .about
            } label: {
                Label("filterList_menu_about"~, systemImage: "info.circle")
            }
        } label: {
            Image(systemName: "ellipsis.circle")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let model = FilterListViewModel(persistanceManager: AppManager.shared.persistanceManager.preview())
        return FilterListView(model: model)
    }
}
