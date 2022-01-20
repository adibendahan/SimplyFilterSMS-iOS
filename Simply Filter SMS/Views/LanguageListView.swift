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
        NavigationView {
            VStack(alignment: .leading) {
                Spacer()
                
                let remainingSupportedLanguages = NLLanguage.allSupportedCases
                    .filter({ !PersistenceController.shared.isDuplicateFilter(text: $0.filterText, type: .denyLanguage) })
                    .sorted(by: { $0.filterText < $1.filterText })
                
                if remainingSupportedLanguages.count > 0 {
                    List {
                        Section {
                            ForEach (remainingSupportedLanguages) { supportedLanguage in
                                if let localizedName = Locale.current.localizedString(forIdentifier: supportedLanguage.rawValue) {
                                    Button {
                                        PersistenceController.shared.addFilter(text: supportedLanguage.filterText, type: .denyLanguage)
                                        dismiss()
                                    } label: {
                                        Text(localizedName)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        } header: {
                            Text("lang_supported"~)
                        } footer: {
                            Text(.init("lang_how"~)) // Dev notes: Markdown text requires the .init workaround
                        } // Section
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
                    .padding()
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
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                }
            }
        } // NavigationView
    }
}

struct LanguageListView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        LanguageListView().environment(\.managedObjectContext, context)
    }
}
