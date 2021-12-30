//
//  FilterListView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/12/2021.
//

import SwiftUI
import CoreData

struct FilterListView: View {
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Filter.type, ascending: false), NSSortDescriptor(keyPath: \Filter.text, ascending: true)],
        animation: .default)
    
    private var filters: FetchedResults<Filter>
    
    @State private var presentedSheet: SheetView? = nil
    
    private var backgroundColor: Color {
        if colorScheme == .light {
            return Color(uiColor: UIColor.secondarySystemBackground)
        }
        else {
            return Color(uiColor: UIColor.systemBackground)
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                let denyList = filters.filter({ Int($0.type) == FilterType.deny.rawValue})
                let allowList = filters.filter({ Int($0.type) == FilterType.allow.rawValue})
                
                if allowList.count > 0 || denyList.count > 0 {
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
                                Text("general_allow"~)
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
                                Text("general_deny"~)
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            EditButton()
                        }
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Menu{
                                Button {
                                    presentedSheet = .addFilter
                                } label: {
                                    Label("addFilter_addFilter"~, systemImage: "plus")
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
                                Image(systemName: "ellipsis.circle.fill")
                            }
                        }
                    }
                    FooterView()
                }
                else {
                    Spacer()
                    Button {
                        presentedSheet = .addFilter
                    } label: {
                        Spacer()
                        Image(systemName: "plus.message.fill")
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
            .navigationTitle("filterList_filters"~)
            .sheet(item: $presentedSheet) { } content: { presentedSheet in
                switch (presentedSheet) {
                case .addFilter:
                    AddFilterView()
                case .about:
                    AboutView()
                case .addLanguageFilter:
                    EmptyView()
                case .enableExtension:
                    EnableExtensionView()
                }
            }
            .background(backgroundColor)
        }
    }
    
    private func FooterView() -> some View {
        Text("Simply Filter SMS v1.0.0\n\(Text("general_copyright"~))")
            .frame(maxWidth: .infinity, alignment: .center)
            .font(.footnote)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        FilterListView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}


enum SheetView: Int, Identifiable {
    var id: Self { self }
    
    case addFilter=0, addLanguageFilter, enableExtension, about
}
