//
//  SmartFilterManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 07/11/2026.
//

import Foundation

class SmartFilterManager: SmartFilterManagerProtocol {

    //MARK: - Initialization -
    init(persistanceManager: PersistanceManagerProtocol = AppManager.shared.persistanceManager) {
        self.persistanceManager = persistanceManager
    }


    //MARK: - Public API (SmartFilterManagerProtocol) -
    var rules: [RuleType] {
        return RuleType.allCases
    }

    func ruleState(for rule: RuleType) -> Bool {
        guard let persistanceManager = self.persistanceManager,
              let automaticFiltersRule = persistanceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return false }
        return automaticFiltersRule.isActive
    }

    func setRuleState(for rule: RuleType, value: Bool) {
        guard let persistanceManager = self.persistanceManager else { return }
        AppManager.logger.debug("setRuleState — '\(rule.title, privacy: .public)' → \(value, privacy: .public)")
        let automaticFiltersRule = persistanceManager.ensuredAutomaticFiltersRuleRecord(for: rule)
        automaticFiltersRule.isActive = value
        if automaticFiltersRule.ruleType == .shortSender && automaticFiltersRule.selectedChoice < 3 {
            automaticFiltersRule.selectedChoice = 6
        }
        _ = persistanceManager.commitAndAnnounce()
    }

    func selectedChoice(for rule: RuleType) -> Int {
        guard let persistanceManager = self.persistanceManager,
              let automaticFiltersRule = persistanceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return 0 }
        return Int(automaticFiltersRule.selectedChoice)
    }

    func setSelectedChoice(for rule: RuleType, choice: Int) {
        guard let persistanceManager = self.persistanceManager,
              let automaticFiltersRule = persistanceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return }
        AppManager.logger.debug("setSelectedChoice — '\(rule.title, privacy: .public)' → \(choice, privacy: .public)")
        automaticFiltersRule.selectedChoice = Int64(choice)
        _ = persistanceManager.commitAndAnnounce()
    }

    func selectedCountries(for rule: RuleType) -> [String] {
        return self.persistanceManager?.selectedCountries(for: rule) ?? []
    }

    func setSelectedCountries(_ countries: [String], for rule: RuleType) {
        AppManager.logger.debug("setSelectedCountries — \(countries, privacy: .public)")
        self.persistanceManager?.setSelectedCountries(countries, for: rule)
    }


    //MARK: - Private  -
    private weak var persistanceManager: PersistanceManagerProtocol?
}
