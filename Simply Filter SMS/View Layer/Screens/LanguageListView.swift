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
    
    @ObservedObject var model: ViewModel
    
    var body: some View {
        switch self.model.mode {
        case .blockLanguage:
            NavigationView {
                self.makeBody()
            }
            .modifier(EmbeddedFooterView(onTap: { self.model.sheetScreen = .about }))
        case .automaticBlocking:
            self.makeBody()
                .modifier(EmbeddedFooterView(onTap: { self.model.sheetScreen = .about }))
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
                                self.model.addFilter(language: language)
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
        .sheet(item: $model.sheetScreen) { } content: { sheetScreen in
            sheetScreen.build()
        }
    }
}


//MARK: - ViewModel -
extension LanguageListView {
    
    enum Mode {
        case blockLanguage, automaticBlocking
    }
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published private(set) var mode: LanguageListView.Mode
        @Published private(set) var title: String
        @Published private(set) var footer: String
        @Published private(set) var lastUpdate: Date?
        @Published private(set) var footerSecondLine: String?
        @Published var languages: [StatefulItem<NLLanguage>] = []
        @Published var sheetScreen: Screen? = nil
        
        init(mode: LanguageListView.Mode,
             appManager: AppManagerProtocol = AppManager.shared) {
            
            let cacheAge = appManager.automaticFilterManager.automaticFiltersCacheAge ?? nil
            
            self.mode = mode
            self.lastUpdate = cacheAge
            self.footer = ViewModel.updatedFooter(for: mode, cacheAge: cacheAge)
            
            
            switch mode {
            case .automaticBlocking:
                self.title = "autoFilter_title"~
                self.footerSecondLine = "help_automaticFiltering"~
            case .blockLanguage:
                self.title = "filterList_menu_filterLanguage"~
                self.footerSecondLine = nil
            }

            self.languages = appManager.automaticFilterManager.languages(for: mode)
                .map({ StatefulItem<NLLanguage>(item: $0,
                                                getter: appManager.automaticFilterManager.languageAutomaticState,
                                                setter: appManager.automaticFilterManager.setLanguageAtumaticState) })
            
            super.init(appManager: appManager)
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
            let cacheAge = self.appManager.automaticFilterManager.automaticFiltersCacheAge ?? nil
            
            self.lastUpdate = cacheAge
            self.footer = ViewModel.updatedFooter(for: self.mode, cacheAge: cacheAge)
            self.languages = self.appManager.automaticFilterManager.languages(for: self.mode)
                .map({ StatefulItem<NLLanguage>(item: $0,
                                                getter: self.appManager.automaticFilterManager.languageAutomaticState,
                                                setter: self.appManager.automaticFilterManager.setLanguageAtumaticState) })
        }
        
        func addFilter(language: NLLanguage) {
            self.appManager.persistanceManager.addFilter(text: language.filterText,
                                                         type: .denyLanguage,
                                                         denyFolder: .junk,
                                                         filterTarget: .body,
                                                         filterMatching: .contains,
                                                         filterCase: .caseInsensitive)
        }
        
        func forceUpdateFilters() {
            self.appManager.automaticFilterManager.forceUpdateAutomaticFilters { [weak self] in
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
        LanguageListView(model: LanguageListView.ViewModel(mode: .blockLanguage, appManager: AppManager.previews))
        
        NavigationView {
            LanguageListView(model: LanguageListView.ViewModel(mode: .automaticBlocking, appManager: AppManager.previews))
        }
    }
}
