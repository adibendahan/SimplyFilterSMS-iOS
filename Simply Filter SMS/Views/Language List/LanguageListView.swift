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

    @Environment(\.dismiss)
    var dismiss
    
    @StateObject var model: LanguageListViewModel
    
    var body: some View {
        switch self.model.type {
        case .blockLanguage:
            NavigationView {
                self.makeBody()
            }
        case .automaticBlocking:
            self.makeBody()
        }
    }
    
    func makeBody() -> some View {
        VStack(alignment: .leading) {
            Spacer()
            
            if !self.model.languages.isEmpty {
                List {
                    Section {
                        ForEach (self.model.languages.indices) { index in
                            let language = $model.languages[index].id
                            if let localizedName = Locale.current.localizedString(forIdentifier: language.rawValue) {
                                switch self.model.type {
                                case .blockLanguage:
                                    Button {
                                        self.model.addFilter(text: language.filterText, type: .denyLanguage)
                                        dismiss()
                                    } label: {
                                        Text(localizedName)
                                            .foregroundColor(.primary)
                                    }
                                    
                                case .automaticBlocking:
                                    Toggle(localizedName, isOn: $model.languages[index].isOn)
                                        .tint(.accentColor)
                                }
                            }
                        }
                    } header: {
                        Text("lang_supported"~)
                    } footer: {
                        HStack {
                            Text(.init(self.model.footer))
                            
                            if let lastUpdate = self.model.lastUpdate,
                               lastUpdate.daysBetween(date: Date()) > 0 {
                                
                                Button {
                                    self.model.forceUpdateFilters()
                                } label: {
                                    Text("autoFilter_forceUpdate"~)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
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
        .navigationTitle(self.model.title)
        .background(Color.listBackgroundColor(for: colorScheme))
        .toolbar {
            ToolbarItem {
                Button {
                    dismiss()
                } label: {
                    switch self.model.type {
                    case .blockLanguage:
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                        
                    case .automaticBlocking:
                        EmptyView()
                    }
                }
                .contentShape(Rectangle())
            }
        }
        .onAppear {
            self.model.refresh()
        }
    }
}

struct LanguageListView_Previews: PreviewProvider {
    static var previews: some View {
        let model = LanguageListViewModel(viewType: .blockLanguage,
                                          persistanceManager: AppManager.shared.persistanceManager.preview)
        LanguageListView(model: model)
    }
}
