//
//  SmartFilterManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 07/11/2026.
//

import Foundation

class SmartFilterManager: SmartFilterManagerProtocol {

    //MARK: - Initialization -
    init(persistenceManager: PersistenceManagerProtocol = AppManager.shared.persistenceManager) {
        self.persistenceManager = persistenceManager
    }


    //MARK: - Public API (SmartFilterManagerProtocol) -
    var rules: [SmartFilterType] {
        return SmartFilterType.allCases
    }

    func ruleState(for rule: SmartFilterType) -> Bool {
        guard let persistenceManager = self.persistenceManager,
              let automaticFiltersRule = persistenceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return false }
        return automaticFiltersRule.isActive
    }

    func setRuleState(for rule: SmartFilterType, value: Bool) {
        guard let persistenceManager = self.persistenceManager else { return }
        AppManager.logger.debug("setRuleState — '\(rule.title, privacy: .public)' → \(value, privacy: .public)")
        let automaticFiltersRule = persistenceManager.ensuredAutomaticFiltersRuleRecord(for: rule)
        automaticFiltersRule.isActive = value
        if automaticFiltersRule.smartFilterType == .shortSender && automaticFiltersRule.selectedChoice < 3 {
            automaticFiltersRule.selectedChoice = 6
        }
        _ = persistenceManager.commitAndAnnounce()
    }

    func selectedChoice(for rule: SmartFilterType) -> Int {
        guard let persistenceManager = self.persistenceManager,
              let automaticFiltersRule = persistenceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return 0 }
        return Int(automaticFiltersRule.selectedChoice)
    }

    func setSelectedChoice(for rule: SmartFilterType, choice: Int) {
        guard let persistenceManager = self.persistenceManager,
              let automaticFiltersRule = persistenceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return }
        AppManager.logger.debug("setSelectedChoice — '\(rule.title, privacy: .public)' → \(choice, privacy: .public)")
        automaticFiltersRule.selectedChoice = Int64(choice)
        _ = persistenceManager.commitAndAnnounce()
    }

    func selectedCountries(for rule: SmartFilterType) -> [String] {
        return self.persistenceManager?.selectedCountries(for: rule) ?? []
    }

    func setSelectedCountries(_ countries: [String], for rule: SmartFilterType) {
        AppManager.logger.debug("setSelectedCountries — \(countries, privacy: .public)")
        self.persistenceManager?.setSelectedCountries(countries, for: rule)
    }


    //MARK: - Private  -
    private weak var persistenceManager: PersistenceManagerProtocol?
}
