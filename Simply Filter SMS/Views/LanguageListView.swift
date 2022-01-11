//
//  LanguageListView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 11/01/2022.
//

import SwiftUI
import NaturalLanguage
import CoreData

struct LanguageListView: View {
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme
    
    @Environment(\.managedObjectContext)
    private var viewContext
    
    @Environment(\.dismiss)
    var dismiss
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                VStack(alignment: .leading) {
                    Spacer()
                    let remainingSupportedLanguages = NLLanguage.allSupportedCases.filter({ !self.isAlreadyBlocked(language: $0) }).sorted(by: { $0.filterText ?? "" < $1.filterText ?? "" })
                    
                    if remainingSupportedLanguages.count > 0 {
                        List {
                            Section {
                                ForEach (remainingSupportedLanguages) { supportedLanguage in
                                    if let localizedName = Locale.current.localizedString(forIdentifier: supportedLanguage.rawValue) {
                                        Button {
                                            addFilter(language: supportedLanguage)
                                            dismiss()
                                        } label: {
                                            Text(localizedName)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                }
                            } header: {
                                Text("Supported languages")
                            } footer: {
                                Text(.init("lang_how"~)) // Dev notes: Markdown text requires the .init workaround
                            }
                        } // List
                        .listStyle(InsetGroupedListStyle())
                    }
                    else {
                        VStack (alignment: .leading) {
                            Text("lang_allBlocked"~)
                            
                            Spacer(minLength: 24)
                            
                            Button {
                                dismiss()
                            } label: {
                                Text("general_close"~)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(FilledButton())
                            .contentShape(Rectangle())
                            
                            Spacer().padding()
                        }
                        .frame(width: geometry.size.width-32, alignment: .center)
                    }
                } // VStack
                .navigationTitle("filterList_menu_filterLanguage"~)
                .background(Color.listBackgroundColor(for: colorScheme))
                .toolbar {
                    ToolbarItem {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold, design: .default))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } // NavigationView
        }
    }
    
    private func isAlreadyBlocked(language: NLLanguage) -> Bool {
        var filterExists = false
        let fetchRequest = NSFetchRequest<Filter>(entityName: "Filter")
        fetchRequest.predicate = NSPredicate(format: "type == %ld AND text == %@", FilterType.denyLanguage.rawValue, language.filterText ?? "")
        
        do {
            let results = try viewContext.fetch(fetchRequest)
            filterExists = results.count > 0
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        
        return filterExists
    }
    
    private func addFilter(language: NLLanguage) {
        guard !self.isAlreadyBlocked(language: language) else { return }
        
        let newFilter = Filter(context: viewContext)
        newFilter.uuid = UUID()
        newFilter.filterType = .denyLanguage
        newFilter.denyFolderType = .junk
        newFilter.text = language.filterText
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

struct LanguageListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        LanguageListView().environment(\.managedObjectContext, context)
    }
}
