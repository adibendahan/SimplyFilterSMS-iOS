//
//  LanguageListViewModel.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation
import NaturalLanguage

class LanguageListViewModel: ObservableObject {
    @Published var languages: [LanguageWithAutomaticState] = []
    @Published var type: LanguageListViewType
    @Published var title: String
    @Published var footer: String
    @Published var lastUpdate: Date?
    
    private let persistanceManager: PersistanceManagerProtocol
    private let automaticFilterManager: AutomaticFilterManagerProtocol
    
    init(viewType: LanguageListViewType,
         persistanceManager: PersistanceManagerProtocol = AppManager.shared.persistanceManager,
         automaticFilterManager: AutomaticFilterManagerProtocol = AppManager.shared.automaticFiltersManager) {
        
        self.automaticFilterManager = automaticFilterManager
        self.persistanceManager = persistanceManager
        self.type = viewType
        self.title = viewType.name
        let cacheAge = persistanceManager.automaticFiltersCacheAge ?? nil
        self.lastUpdate = cacheAge
        
        self.footer = LanguageListViewModel.updatedFooter(for: viewType, cacheAge: cacheAge)
    }
    
    private static func updatedFooter(for type: LanguageListViewType, cacheAge: Date?) -> String {
        switch type {
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
        self.languages = self.persistanceManager.languages(for: self.type).map({ LanguageWithAutomaticState(language: $0,
                                                                                                            persistanceManager: self.persistanceManager) })
        let cacheAge = persistanceManager.automaticFiltersCacheAge ?? nil
        self.lastUpdate = cacheAge
        
        self.footer = LanguageListViewModel.updatedFooter(for: self.type, cacheAge: cacheAge)
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
}

struct LanguageWithAutomaticState: Identifiable, Equatable {

    private var persistanceManager: PersistanceManagerProtocol
    
    var id: NLLanguage
    var isOn: Bool {
        didSet {
            self.persistanceManager.setLanguageAtumaticState(for: id, value: self.isOn)
        }
    }

    init(language: NLLanguage,
         persistanceManager: PersistanceManagerProtocol = AppManager.shared.persistanceManager) {
        
        self.persistanceManager = persistanceManager
        self.id = language
        self.isOn = persistanceManager.languageAutomaticState(for: language)
    }
    
    static func == (lhs: LanguageWithAutomaticState, rhs: LanguageWithAutomaticState) -> Bool {
        return lhs.id == rhs.id
    }
}
