//
//  FilterListView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/12/2021.
//

import SwiftUI
import CoreData

struct FilterListView: View {
    @Environment(\.isPreview) var isPreview
    @Environment(\.isDebug) var isDebug
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(fetchRequest: getFiltersFetchRequest)
    private var filters: FetchedResults<Filter>
    
    @State private var presentedSheet: SheetView? = nil
    @State private var isPresentingFullScreenWelcome = false
    
    private var backgroundColor: Color {
        if colorScheme == .light {
            return Color(uiColor: UIColor.secondarySystemBackground)
        }
        else {
            return Color(uiColor: UIColor.systemBackground)
        }
    }
    
    private static var getFiltersFetchRequest: NSFetchRequest<Filter> {
        let request: NSFetchRequest<Filter> = Filter.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Filter.type, ascending: false),
                                   NSSortDescriptor(keyPath: \Filter.text, ascending: true)]
        return request
   }
    
    var body: some View {
        NavigationView {
            VStack {
                let denyList = filters.filter({ Int($0.type) == FilterType.deny.rawValue})
                let allowList = filters.filter({ Int($0.type) == FilterType.allow.rawValue})
                let denyLanguageList = filters.filter({ Int($0.type) == FilterType.denyLanguage.rawValue})
                
                if allowList.count > 0 || denyList.count > 0 || denyLanguageList.count > 0 {
                    List {
                        if denyLanguageList.count > 0 {
                            Section {
                                ForEach(denyLanguageList, id: \.self) { filter in
                                    let lang = FilteredLanguage(rawValue: filter.text ?? FilteredLanguage.unknown.rawValue) ?? FilteredLanguage.unknown
                                    Text(lang.name)
                                }
                                .onDelete {
                                    self.deleteFilters(withOffsets: $0, in: denyLanguageList)
                                }
                            } header: {
                                Text("filterList_deniedLanguage"~)
                            }
                        }
                        
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
                        
                        if denyList.count > 0 {
                            Section {
                                ForEach(denyList, id: \.self) { filter in
                                    Text(filter.text ?? "general_null"~)
                                }
                                .onDelete {
                                    self.deleteFilters(withOffsets: $0, in: denyList)
                                }
                            } header: {
                                Text("filterList_denied"~)
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
                                loadDebugData()
                            } label: {
                                Label("filterList_menu_debug"~, systemImage: "chevron.left.forwardslash.chevron.right")
                            }
                        }
                        Button {
                            presentedSheet = .addFilter
                        } label: {
                            Label("addFilter_addFilter"~, systemImage: "plus.circle")
                        }
                        Menu {
                            Button {
                                addFilter(language: .arabic)
                            } label: {
                                Text("lang_arabic"~)
                            }
                            Button {
                                addFilter(language: .hebrew)
                            } label: {
                                Text("lang_hebrew"~)
                            }
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
                }
            }
            .fullScreenCover(isPresented: $isPresentingFullScreenWelcome, onDismiss: { }, content: {
                EnableExtensionView(isFromMenu: false)
            })
            .background(backgroundColor)
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
    
    private func addFilter(language: FilteredLanguage) {
        guard !filters.map({ $0.text ?? FilteredLanguage.unknown.rawValue }).map(({ FilteredLanguage(rawValue: $0) })).contains(language) else { return }
        
        withAnimation {
            let newFilter = Filter(context: viewContext)
            newFilter.uuid = UUID()
            newFilter.type = Int64(FilterType.denyLanguage.rawValue)
            newFilter.text = language.rawValue

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    private func loadDebugData() {
        let _ = ["Adi", "דהאן", "דהן", "עדי"].map { allowText -> Filter in
            let newFilter = Filter(context: viewContext)
            newFilter.uuid = UUID()
            newFilter.type = Int64(FilterType.allow.rawValue)
            newFilter.text = allowText
            return newFilter
        }
        let _ = ["גנץ", "הימור", "הלוואה", "נתניהו"].map { allowText -> Filter in
            let newFilter = Filter(context: viewContext)
            newFilter.uuid = UUID()
            newFilter.type = Int64(FilterType.deny.rawValue)
            newFilter.text = allowText
            return newFilter
        }
    
        let langFilter = Filter(context: viewContext)
        langFilter.uuid = UUID()
        langFilter.type = Int64(FilterType.denyLanguage.rawValue)
        langFilter.text = FilteredLanguage.arabic.rawValue
        
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
    
    case addFilter=0, enableExtension, about
}
