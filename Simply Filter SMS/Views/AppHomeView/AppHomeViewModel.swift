//
//  AppHomeViewModel.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 31/01/2022.
//

import Foundation

class AppHomeViewModel: ObservableObject {
    @Published var filters: [Filter] = []
    @Published var rules: [StatefulItem<RuleType>] = []
    @Published var title: String
    @Published var isAppFirstRun: Bool
    @Published var isAutomaticFilteringOn: Bool
    @Published var isAllUnknownFilteringOn: Bool
    @Published var lastUpdate: Date?
    @Published var shortSenderChoice: Int
    @Published var activeNavigationTag: String?
    @Published var activeLanguages: String
    @Published var automaticFilteringFooter: String
    
    private let persistanceManager: PersistanceManagerProtocol
    private let defaultsManager: DefaultsManagerProtocol
    private let automaticFilterManager: AutomaticFilterManagerProtocol
    
    init(persistanceManager: PersistanceManagerProtocol = AppManager.shared.persistanceManager,
         defaultsManager: DefaultsManagerProtocol = AppManager.shared.defaultsManager,
         automaticFilterManager: AutomaticFilterManagerProtocol = AppManager.shared.automaticFiltersManager) {

        let isAutomaticFilteringOn = automaticFilterManager.isAutomaticFilteringOn
        let cacheAge = automaticFilterManager.automaticFiltersCacheAge
        
        self.automaticFilterManager = automaticFilterManager
        self.persistanceManager = persistanceManager
        self.defaultsManager = defaultsManager
        
        self.title = "filterList_filters"~
        self.isAppFirstRun = defaultsManager.isAppFirstRun
        self.isAutomaticFilteringOn = isAutomaticFilteringOn
        self.isAllUnknownFilteringOn = automaticFilterManager.automaticRuleState(for: .allUnknown)
        self.lastUpdate = cacheAge
        self.shortSenderChoice = automaticFilterManager.selectedChoice(for: .shortSender)
        self.activeNavigationTag = nil
        self.activeLanguages = isAutomaticFilteringOn ? automaticFilterManager.activeAutomaticFiltersTitle ?? "" : ""

        if let cacheAge = cacheAge {
            let formatter = DateFormatter()
            formatter.locale = Locale.current
            formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "ddMMyyyy", options: 0, locale: Locale.current)
            self.automaticFilteringFooter = String(format: "autoFilter_lastUpdated"~, formatter.string(from: cacheAge))
            
        }
        else
        {
            self.automaticFilteringFooter = ""
        }
        
        self.filters = persistanceManager.fetchFilterRecords()
        self.rules = automaticFilterManager.rules.map({ StatefulItem<RuleType>(item: $0,
                                                                               getter: self.automaticFilterManager.automaticRuleState,
                                                                               setter: self.setAutomaticRuleState) }).sorted(by: { $0.id.sortIndex < $1.id.sortIndex })
    }
    
    func refresh() {
        let isAutomaticFilteringOn = self.automaticFilterManager.isAutomaticFilteringOn
        let cacheAge = automaticFilterManager.automaticFiltersCacheAge ?? nil
        
        self.title = "filterList_filters"~

        self.isAppFirstRun = self.defaultsManager.isAppFirstRun
        self.isAutomaticFilteringOn = isAutomaticFilteringOn
        self.isAllUnknownFilteringOn = self.automaticFilterManager.automaticRuleState(for: .allUnknown)
        self.lastUpdate = cacheAge
        self.shortSenderChoice = self.automaticFilterManager.selectedChoice(for: .shortSender)
        self.activeLanguages = isAutomaticFilteringOn ? self.automaticFilterManager.activeAutomaticFiltersTitle ?? "" : ""
        self.filters = persistanceManager.fetchFilterRecords()
        self.rules = self.automaticFilterManager.rules.map({ StatefulItem<RuleType>(item: $0,
                                                                                    getter: self.automaticFilterManager.automaticRuleState,
                                                                                    setter: self.setAutomaticRuleState) }).sorted(by: { $0.id.sortIndex < $1.id.sortIndex })
        
    }
    
    func setSelectedChoice(for rule: RuleType, choice: Int) {
        self.automaticFilterManager.setSelectedChoice(for: rule, choice: choice)
        self.refresh()
    }
    
    func activeCount(for filterType: FilterType) -> Int {
        return self.filters.filter({ $0.filterType == filterType }).count
    }
    
    func forceUpdateFilters() {
            self.automaticFilterManager.forceUpdateAutomaticFilters { [weak self] in
                DispatchQueue.main.async {
                    self?.refresh()
                }
            }
        }
    
    func loadDebugData() {
        self.persistanceManager.loadDebugData()
        self.refresh()
    }
    
    private func setAutomaticRuleState(for rule: RuleType, value: Bool) {
        self.automaticFilterManager.setAutomaticRuleState(for: rule, value: value)
        self.refresh()
    }
}
