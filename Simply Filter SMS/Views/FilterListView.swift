//
//  FilterListView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/12/2021.
//

import SwiftUI
import CoreData
import NaturalLanguage

enum FilterListSheetView: Int, Identifiable {
    var id: Self { self }
    
    case addFilter=0, enableExtension, about, addLanguageFilter
}

struct FilterListView: View {
    
    @Environment(\.isPreview)
    var isPreview
    
    @Environment(\.isDebug)
    var isDebug
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme
    
    @Environment(\.managedObjectContext)
    private var viewContext
    
    @FetchRequest(fetchRequest: PersistenceController.getFiltersFetchRequest)
    private var filters: FetchedResults<Filter>
    
    @State private var presentedSheet: FilterListSheetView? = nil
    @State private var isPresentingFullScreenWelcome = false
    @State private var selectedFilters: Set<Filter> = Set()
    @State var editMode: EditMode = .inactive
    
    var body: some View {
        NavigationView {
            ZStack (alignment: .bottom) {
                let denyList = filters.filter({ $0.filterType == .deny })
                let allowList = filters.filter({ $0.filterType == .allow })
                let denyLanguageList = filters.filter({ $0.filterType == .denyLanguage })
                
                List (selection: $selectedFilters) {
                    if filters.count == 0 {
                        Section {
                            
                        } footer: {
                            AddFilterButton()
                                .padding(.top, 120)
                        }
                    }
                    
                    if allowList.count > 0 {
                        Section{
                            ForEach(allowList, id: \.self) { filter in
                                Text(filter.text ?? "general_null"~)
                            }
                            .onDelete {
                                PersistenceController.shared.deleteFilters(withOffsets: $0, in: allowList)
                            }
                        } header: {
                            Text("filterList_allowed"~)
                        } footer: {
                            if denyList.count == 0 && denyLanguageList.count == 0 {
                                AddFilterButton()
                            }
                        }
                    }
                    
                    if denyLanguageList.count > 0 {
                        Section {
                            ForEach(denyLanguageList, id: \.self) { filter in
                                if let filterText = filter.text,
                                   let blockedLanguage = NLLanguage(filterText: filterText),
                                   blockedLanguage != .undetermined,
                                   let localizedName = Locale.current.localizedString(forIdentifier: blockedLanguage.rawValue) {
                                    
                                    HStack (alignment: .center , spacing: 0) {
                                        Text(localizedName)
                                        
                                        Spacer()
                                        
                                        Menu {
                                            ForEach(DenyFolderType.allCases) { folder in
                                                Button {
                                                    PersistenceController.shared.updateFilter(filter, denyFolder: folder)
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
                                    }
                                    .environment(\.editMode, self.$editMode)
                                }
                            }
                            .onDelete {
                                PersistenceController.shared.deleteFilters(withOffsets: $0, in: denyLanguageList)
                            }
                        } header: {
                            HStack {
                                Text("filterList_deniedLanguage"~)
                                
                                Spacer()
                                
                                Text("Folder")
                            }
                        } footer: {
                            if denyList.count == 0 {
                                AddFilterButton()
                            }
                        }
                    }
                    
                    if denyList.count > 0 {
                        Section {
                            ForEach(denyList, id: \.self) { filter in
                                HStack (alignment: .center , spacing: 0) {
                                    Text(filter.text ?? "general_null"~)
                                    
                                    Spacer()
                                    
                                    Menu {
                                        ForEach(DenyFolderType.allCases) { folder in
                                            Button {
                                                PersistenceController.shared.updateFilter(filter, denyFolder: folder)
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
                                .environment(\.editMode, self.$editMode)
                            } // ForEach
                            .onDelete {
                                PersistenceController.shared.deleteFilters(withOffsets: $0, in: denyList)
                            }
                        } header: {
                            HStack {
                                Text("filterList_denied"~)
                                
                                Spacer()
                                
                                Text("Folder")
                            }
                        } footer: {
                            AddFilterButton()
                        } // Section
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .navigationBarItems(leading: EditButton())
                .navigationBarItems(trailing: NavigationBarItemTrailing())
                .navigationTitle("filterList_filters"~)
                .sheet(item: $presentedSheet) { } content: { presentedSheet in
                    switch (presentedSheet) {
                    case .addFilter:
                        AddFilterView()
                    case .about:
                        AboutView()
                    case .enableExtension:
                        HelpView(questions: PersistenceController.frequentlyAskedQuestions)
                    case .addLanguageFilter:
                        LanguageListView()
                    }
                }
                .fullScreenCover(isPresented: $isPresentingFullScreenWelcome, onDismiss: { }, content: {
                    EnableExtensionView(isFromMenu: false)
                })
                .background(Color.listBackgroundColor(for: colorScheme))
                .onAppear() {
                    if !isPreview && UserDefaults.isAppFirstRun {
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
    }
    
    private func AddFilterButton() -> some View {
        Button {
            presentedSheet = .addFilter
        } label: {
            Spacer()
            
            Image(systemName: "plus.message")
                .imageScale(.large)
                .font(.system(size: 20, weight: .bold))
            
            Text("filterList_addFilters"~)
                .font(.body)
            
            Spacer()
        }
        .padding(.top, 1)
        .padding(.bottom, 40)
    }
    
    @ViewBuilder
    private func NavigationBarItemTrailing() -> some View {
        if editMode.isEditing {
                Button(role: .destructive,
                       action: {
                           withAnimation {
                               PersistenceController.shared.deleteFilters(selectedFilters)
                               self.editMode = .inactive
                           }
                       },
                       label: {
                           Text(String(format: "filterList_deleteFiltersCount"~, selectedFilters.count))
                               .foregroundColor(.red)
                       })
        }
        else {
            MenuView()
        }
    }
    
    private func MenuView() -> some View {
        Menu {
            if isDebug && filters.count == 0 {
                Button {
                    PersistenceController.shared.loadDebugData()
                } label: {
                    Label("filterList_menu_debug"~, systemImage: "chevron.left.forwardslash.chevron.right")
                }
            }
            
            Button {
                presentedSheet = .addFilter
            } label: {
                Label("addFilter_addFilter"~, systemImage: "plus.circle")
            }
            
            Button {
                presentedSheet = .addLanguageFilter
            } label: {
                Label("filterList_menu_filterLanguage"~, systemImage: "globe")
            }
            
            Button {
                presentedSheet = .enableExtension
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
        let context = PersistenceController.preview.container.viewContext
        return FilterListView().environment(\.managedObjectContext, context)
    }
}
