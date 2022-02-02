//
//  LanguageListViewModel.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation
import NaturalLanguage

class LanguageListViewModel: ObservableObject {
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
        self.footer = LanguageListViewModel.updatedFooter(for: mode, cacheAge: cacheAge)

        
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
        self.footer = LanguageListViewModel.updatedFooter(for: self.mode, cacheAge: cacheAge)
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
