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
    
    private let persistanceManager: PersistanceManagerProtocol
    
    init(persistanceManager: PersistanceManagerProtocol,
         viewType: LanguageListViewType) {
        
        self.persistanceManager = persistanceManager
        self.type = viewType
        self.title = viewType.name
        self.footer = viewType.footer
    }
    
    func fetchLanguages() {
        self.languages = self.persistanceManager.languages(for: self.type).map({ LanguageWithAutomaticState(language: $0) })
    }
    
    func addFilter(text: String, type: FilterType, denyFolder: DenyFolderType = .junk) {
        self.persistanceManager.addFilter(text: text, type: type, denyFolder: denyFolder)
        self.fetchLanguages()
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
