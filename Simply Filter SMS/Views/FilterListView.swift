//
//  FilterListView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/12/2021.
//

import SwiftUI
import CoreData

struct FilterListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Filter.type, ascending: false), NSSortDescriptor(keyPath: \Filter.text, ascending: true)],
        animation: .default)
    
    private var filters: FetchedResults<Filter>
    
    @State private var addFilterButton = false
    
    var body: some View {
        NavigationView {
            VStack {
                let denyList = filters.filter({ Int($0.type) == FilterType.deny.rawValue})
                let allowList = filters.filter({ Int($0.type) == FilterType.allow.rawValue})
                
                if allowList.count > 0 || denyList.count > 0 {
                    List {
                        if denyList.count > 0 {
                            Section {
                                ForEach(denyList, id: \.self) { filter in
                                    Text(filter.text ?? "(null)")
                                }
                                .onDelete {
                                    self.deleteFilters(withOffsets: $0, in: denyList)
                                }
                            } header: {
                                Text("Deny")
                            }
                        }
                        
                        if allowList.count > 0 {
                            Section{
                                ForEach(allowList, id: \.self) { filter in
                                    Text(filter.text ?? "(null)")
                                }
                                .onDelete {
                                    self.deleteFilters(withOffsets: $0, in: allowList)
                                }
                            } header: {
                                Text("Allow")
                            }
                        }
                    }
                    .listStyle(InsetGroupedListStyle())
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            EditButton()
                        }
                        ToolbarItem {
                            Button {
                                addFilterButton = true
                            } label: {
                                Label("Add filter", systemImage: "plus")
                            }
                        }
                    }
                    FooterView()
                }
                else {
                    Spacer()
                    Button {
                        addFilterButton = true
                    } label: {
                        Spacer()
                        Image(systemName: "plus.message.fill")
                            .imageScale(.large)
                            .font(.system(size: 34, weight: .bold))
                        Text("Add filters")
                            .font(.body)
                        Spacer()
                    }
                    Spacer()
                    FooterView()
                }
            }
            .navigationTitle("Filters")
            .sheet(isPresented: $addFilterButton) {
                AddFilterView()
            }
        }
    }
    
    private func FooterView() -> some View {
        Text("Simply Filter SMS v1.0.0\n© 2021 Adi Ben-Dahan. All rights reserved.")
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
