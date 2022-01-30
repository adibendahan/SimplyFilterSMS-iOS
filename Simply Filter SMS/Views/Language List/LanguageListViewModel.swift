//
//  LanguageListViewModel.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation
import NaturalLanguage

class LanguageListViewModel: ObservableObject {
    @Published var languages: [StatefulItem<NLLanguage>] = []
    @Published var mode: LanguageListView.Mode
    @Published var title: String
    @Published var footer: String
    @Published var lastUpdate: Date?
    @Published var rules: [StatefulItem<RuleType>] = []
    @Published var shortSenderChoice: Int
    
    private let persistanceManager: PersistanceManagerProtocol
    private let automaticFilterManager: AutomaticFilterManagerProtocol
    
    init(mode: LanguageListView.Mode,
         persistanceManager: PersistanceManagerProtocol = AppManager.shared.persistanceManager,
         automaticFilterManager: AutomaticFilterManagerProtocol = AppManager.shared.automaticFiltersManager) {
        
        let cacheAge = persistanceManager.automaticFiltersCacheAge ?? nil
        
        self.automaticFilterManager = automaticFilterManager
        self.persistanceManager = persistanceManager
        self.mode = mode
        self.lastUpdate = cacheAge
        self.footer = LanguageListViewModel.updatedFooter(for: mode, cacheAge: cacheAge)
        self.shortSenderChoice = persistanceManager.selectedChoice(for: .shortSender)
        
        switch mode {
        case .automaticBlocking:
            self.title = "autoFilter_title"~
            self.rules = automaticFilterManager.availableRules.map({ StatefulItem<RuleType>(item: $0,
                                                                                            getter: self.automaticFilterManager.automaticRuleState,
                                                                                            setter: self.automaticFilterManager.setAutomaticRuleState) })
        case .blockLanguage:
            self.title = "filterList_menu_filterLanguage"~
        }
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
        let cacheAge = persistanceManager.automaticFiltersCacheAge ?? nil
        
        self.lastUpdate = cacheAge
        self.footer = LanguageListViewModel.updatedFooter(for: self.mode, cacheAge: cacheAge)
        self.shortSenderChoice = persistanceManager.selectedChoice(for: .shortSender)
        self.languages = self.persistanceManager.languages(for: self.mode).map({ StatefulItem<NLLanguage>(item: $0,
                                                                                                          getter: self.persistanceManager.languageAutomaticState,
                                                                                                          setter: self.persistanceManager.setLanguageAtumaticState) })
        
        if self.mode == .automaticBlocking {
            self.rules = self.automaticFilterManager.availableRules.map({ StatefulItem<RuleType>(item: $0,
                                                                                                 getter: self.automaticFilterManager.automaticRuleState,
                                                                                                 setter: self.automaticFilterManager.setAutomaticRuleState) })
        }
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
    
    func setSelectedChoice(for rule: RuleType, choice: Int) {
        self.persistanceManager.setSelectedChoice(for: rule, choice: choice)
        self.refresh()
    }
}
