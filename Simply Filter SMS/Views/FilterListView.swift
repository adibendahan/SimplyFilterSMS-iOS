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
    
    @Environment(\.managedObjectContext)
    private var viewContext
    
    @FetchRequest(fetchRequest: PersistenceController.getFiltersFetchRequest)
    private var filters: FetchedResults<Filter>
    
    @State private var presentedSheet: SheetView? = nil
    @State private var isPresentingFullScreenWelcome = false
    
    var body: some View {
        NavigationView {
            VStack {
                let denyList = filters.filter({ $0.filterType == .deny })
                let allowList = filters.filter({ $0.filterType == .allow })
                let denyLanguageList = filters.filter({ $0.filterType == .denyLanguage })
                
                if allowList.count > 0 || denyList.count > 0 || denyLanguageList.count > 0 {
                    List {
                        
                        if allowList.count > 0 {
                            Section{
                                ForEach(allowList, id: \.self) { filter in
                                    Text(filter.text ?? "general_null"~)
                                }
                                .onDelete {
                                    self.deleteFilters(withOffsets: $0, in: allowList)
                                }
                            } header: {
                                Text("filterList_allowed"~)
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
                                                        updateFilter(filter, denyFolder: folder)
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
                                    }
                                    
                                }
                                .onDelete {
                                    self.deleteFilters(withOffsets: $0, in: denyLanguageList)
                                }
                            } header: {
                                HStack {
                                    Text("filterList_deniedLanguage"~)
                                    
                                    Spacer()
                                    
                                    Text("Folder")
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
                                                    updateFilter(filter, denyFolder: folder)
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
                                }
                                .onDelete {
                                    self.deleteFilters(withOffsets: $0, in: denyList)
                                }
                            } header: {
                                HStack {
                                    Text("filterList_denied"~)
                                    
                                    Spacer()
                                    
                                    Text("Folder")
                                }
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    FooterView()
                }
                else {
                    Spacer()
                    
                    Button {
                        presentedSheet = .addFilter
                    } label: {
                        Spacer()
                        
                        Image(systemName: "plus.message")
                            .imageScale(.large)
                            .font(.system(size: 34, weight: .bold))
                        
                        Text("filterList_addFilters"~)
                            .font(.body)
                        
                        Spacer()
                    }
                    
                    Spacer()
                    
                    FooterView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if filters.count > 0 {
                        EditButton()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
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
            .navigationTitle("filterList_filters"~)
            .sheet(item: $presentedSheet) { } content: { presentedSheet in
                switch (presentedSheet) {
                case .addFilter:
                    AddFilterView()
                case .about:
                    AboutView()
                case .enableExtension:
                    EnableExtensionView(isFromMenu: true)
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
        }
    }
    
    private func FooterView() -> some View {
        Text("Simply Filter SMS v\(Text(appVersion))\n\(Text("general_copyright"~))")
            .frame(maxWidth: .infinity, alignment: .center)
            .font(.footnote)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .onTapGesture {
                self.presentedSheet = .about
            }
    }
    
    private func deleteFilters(withOffsets offsets: IndexSet, in filters: [Filter]) {
        withAnimation {
            offsets.map({ filters[$0] }).forEach({ viewContext.delete($0) })
            
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func updateFilter(_ filter: Filter, denyFolder: DenyFolderType) {
        filter.denyFolderType = denyFolder
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        return FilterListView().environment(\.managedObjectContext, context)
    }
}


enum SheetView: Int, Identifiable {
    var id: Self { self }
    
    case addFilter=0, enableExtension, about, addLanguageFilter
}
