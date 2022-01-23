//
//  LanguageListView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 11/01/2022.
//

import SwiftUI
import NaturalLanguage
import CoreData

enum LanguageListViewType {
    case blockLanguage, automaticBlocking
    
    var name: String {
        switch self {
        case .blockLanguage:
            return "filterList_menu_filterLanguage"~
        case .automaticBlocking:
            return "autoFilter_title"~
        }
    }
    
    var footer: String {
        switch self {
        case .blockLanguage:
            return "lang_how"~
        case .automaticBlocking:
            return String(format: "autoFilter_lastUpdated"~, Date().description)
        }
    }
}

struct LanguageWithAutomaticState: Identifiable, Equatable {
    var id: NLLanguage
    var isOn: Bool {
        didSet (newValue) {
            AppManager.shared.defaultsManager.setLanguageAtumaticState(for: id, value: newValue)
        }
    }

    init(language: NLLanguage) {
        self.id = language
        self.isOn = AppManager.shared.defaultsManager.languageAutomaticState(for: language)
    }
}

struct LanguageListView: View {
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme

    @Environment(\.dismiss)
    var dismiss
    
    @State var appManager: AppManagerProtocol = AppManager.shared
    @State var viewType: LanguageListViewType
    @State var languages: [LanguageWithAutomaticState]
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                Spacer()
                
                if languages.count > 0 {
                    List {
                        Section {
                            ForEach (languages.indices) { index in
                                let language = $languages[index].id
                                if let localizedName = Locale.current.localizedString(forIdentifier: language.rawValue) {
                                    switch viewType {
                                    case .blockLanguage:
                                        Button {
                                            self.appManager.persistanceManager.addFilter(text: language.filterText, type: .denyLanguage, denyFolder: .junk)
                                            dismiss()
                                        } label: {
                                            Text(localizedName)
                                                .foregroundColor(.primary)
                                        }
                                        
                                    case .automaticBlocking:
                                        Toggle(localizedName, isOn: $languages[index].isOn)
                                    }
                                }
                            }
                        } header: {
                            Text("lang_supported"~)
                        } footer: {
                            Text(.init(viewType.footer))
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
            .navigationTitle(viewType.name)
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
    
    init(type: LanguageListViewType) {
        let languages = _appManager.wrappedValue.persistanceManager.languages(for: type)
        _viewType = State(initialValue: type)
        _languages = State(initialValue: languages.map({ LanguageWithAutomaticState(language: $0) }))
    }
}

struct LanguageListView_Previews: PreviewProvider {
    static var previews: some View {
        LanguageListView(type: .automaticBlocking)
            .environment(\.managedObjectContext, AppManager.shared.persistanceManager.preview().context)
    }
}
