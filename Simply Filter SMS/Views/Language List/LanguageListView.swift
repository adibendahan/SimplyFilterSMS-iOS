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
    
    enum Mode {
        case blockLanguage, automaticBlocking
    }
    
    @StateObject var model: LanguageListViewModel
    
    var body: some View {
        switch self.model.mode {
        case .blockLanguage:
            NavigationView {
                self.makeBody()
            }
        case .automaticBlocking:
            self.makeBody()
        }
    }
    
    @ViewBuilder
    func makeBody() -> some View {
        List {
            Section {
                ForEach (self.model.languages.indices) { index in
                    let language = model.languages[index].item
                    
                    if let localizedName = language.localizedName {
                        switch self.model.mode {
                        case .blockLanguage:
                            Button {
                                self.model.addFilter(text: language.filterText, type: .denyLanguage)
                                dismiss()
                            } label: {
                                Text(localizedName)
                                    .foregroundColor(.primary)
                            }
                            
                        case .automaticBlocking:
                            Toggle(localizedName, isOn: $model.languages[index].state)
                                .tint(.accentColor)
                        }
                    }
                }
            } header: {
                Text("lang_supported"~)
            } footer: {
                HStack {
                    Text(.init(self.model.footer))
                    
                    if self.model.mode == .automaticBlocking,
                       let lastUpdate = self.model.lastUpdate,
                       lastUpdate.daysBetween(date: Date()) > 0 {
                        
                        Button {
                            self.model.forceUpdateFilters()
                        } label: {
                            Text("autoFilter_forceUpdate"~)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } // Section
        } // List
        .listStyle(.insetGrouped)
        .navigationTitle(self.model.title)
        .navigationBarTitleDisplayMode(self.model.mode == .blockLanguage ? .large : .inline)
        .toolbar {
            ToolbarItem {
                Button {
                    dismiss()
                } label: {
                    switch self.model.mode {
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
        let model = LanguageListViewModel(mode: .automaticBlocking,
                                          persistanceManager: AppManager.shared.previewsPersistanceManager)
        LanguageListView(model: model)
    }
}
