//
//  LanguageListView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 11/01/2022.
//

import SwiftUI
import NaturalLanguage
import CoreData


//MARK: - View -
struct LanguageListView: View {
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme
    
    @Environment(\.dismiss)
    var dismiss
    
    enum Mode {
        case blockLanguage, automaticBlocking
    }
    
    @StateObject var model: Model
    
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
                VStack {
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
                    
                    if let helpText = self.model.footerSecondLine {
                        Spacer(minLength: 20)
                        
                        Text(helpText)
                            .multilineTextAlignment(.leading)
                    }
                }
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


//MARK: - Model -
extension LanguageListView {
    
    class Model: ObservableObject {
        @Published var languages: [StatefulItem<NLLanguage>]
        @Published var mode: LanguageListView.Mode
        @Published var title: String
        @Published var footer: String
        @Published var lastUpdate: Date?
        @Published var footerSecondLine: String?
        
        private let persistanceManager: PersistanceManagerProtocol
        private let automaticFilterManager: AutomaticFilterManagerProtocol
        
        init(mode: LanguageListView.Mode,
             persistanceManager: PersistanceManagerProtocol = AppManager.shared.persistanceManager,
             automaticFilterManager: AutomaticFilterManagerProtocol = AppManager.shared.automaticFiltersManager) {
            
            let cacheAge = automaticFilterManager.automaticFiltersCacheAge ?? nil
            
            self.automaticFilterManager = automaticFilterManager
            self.persistanceManager = persistanceManager
            self.mode = mode
            self.lastUpdate = cacheAge
            self.footer = Model.updatedFooter(for: mode, cacheAge: cacheAge)
            
            
            switch mode {
            case .automaticBlocking:
                self.title = "autoFilter_title"~
                self.footerSecondLine = "help_automaticFiltering"~
            case .blockLanguage:
                self.title = "filterList_menu_filterLanguage"~
                self.footerSecondLine = nil
            }
            
            self.languages = automaticFilterManager.languages(for: mode)
                .map({ StatefulItem<NLLanguage>(item: $0,
                                                getter: automaticFilterManager.languageAutomaticState,
                                                setter: automaticFilterManager.setLanguageAtumaticState) })
        }
        
        private static func updatedFooter(for mode: LanguageListView.Mode, cacheAge: Date?) -> String {
            switch mode {
            case .blockLanguage:
                return "lang_how"~
                
            case .automaticBlocking:
                let formatter = DateFormatter()
                formatter.locale = Locale.current
                formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "ddMMyyyy HHmm", options: 0, locale: Locale.current)
                
                
                if let date = cacheAge {
                    return String(format: "autoFilter_lastUpdated"~, formatter.string(from: date))
                }
                else
                {
                    return String(format: "autoFilter_lastUpdated"~, "autoFilter_neverUpdated"~)
                }
            }
        }
        
        func refresh() {
            let cacheAge = self.automaticFilterManager.automaticFiltersCacheAge ?? nil
            
            self.lastUpdate = cacheAge
            self.footer = Model.updatedFooter(for: self.mode, cacheAge: cacheAge)
            self.languages = self.automaticFilterManager.languages(for: self.mode)
                .map({ StatefulItem<NLLanguage>(item: $0,
                                                getter: self.automaticFilterManager.languageAutomaticState,
                                                setter: self.automaticFilterManager.setLanguageAtumaticState) })
        }
        
        func addFilter(text: String, type: FilterType, denyFolder: DenyFolderType = .junk) {
            self.persistanceManager.addFilter(text: text, type: type, denyFolder: denyFolder)
        }
        
        func forceUpdateFilters() {
            self.automaticFilterManager.forceUpdateAutomaticFilters { [weak self] in
                DispatchQueue.main.async {
                    self?.refresh()
                }
            }
        }
    }
}


//MARK: - Preview -
struct LanguageListView_Previews: PreviewProvider {
    static var previews: some View {
        let model = LanguageListView.Model(mode: .automaticBlocking,
                                           persistanceManager: AppManager.shared.previewsPersistanceManager)
        LanguageListView(model: model)
    }
}
