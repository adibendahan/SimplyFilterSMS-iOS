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
    var smartFilterTypes: [SmartFilterType] {
        return SmartFilterType.allCases
    }

    func isSmartFilterActive(for rule: SmartFilterType) -> Bool {
        guard let persistenceManager = self.persistenceManager,
              let automaticFiltersRule = persistenceManager.fetchAutomaticFiltersRuleRecord(for: rule) else { return false }
        return automaticFiltersRule.isActive
    }

    func setSmartFilterActive(for rule: SmartFilterType, value: Bool) {
        guard let persistenceManager = self.persistenceManager else { return }
        let automaticFiltersRule = persistenceManager.ensuredAutomaticFiltersRuleRecord(for: rule)
        Log.debug("rule changed, rule: \(rule), active: \(automaticFiltersRule.isActive) → \(value)")
        automaticFiltersRule.isActive = value
        if automaticFiltersRule.smartFilterType == .shortSender && automaticFiltersRule.selectedChoice < 3 {
            let oldChoice = automaticFiltersRule.selectedChoice
            automaticFiltersRule.selectedChoice = 6
            Log.debug("choice below minimum, rule: \(rule), choice: \(oldChoice) → \(automaticFiltersRule.selectedChoice)")
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
              let automaticFiltersRule = persistenceManager.fetchAutomaticFiltersRuleRecord(for: rule) else {
            Log.debug("no record, rule: \(rule), choice: \(choice) → skipped")
            return
        }
        Log.debug("choice changed, rule: \(rule), choice: \(automaticFiltersRule.selectedChoice) → \(choice)")
        automaticFiltersRule.selectedChoice = Int64(choice)
        _ = persistenceManager.commitAndAnnounce()
    }

    func selectedCountries(for rule: SmartFilterType) -> [String] {
        return self.persistenceManager?.selectedCountries(for: rule) ?? []
    }

    func setSelectedCountries(_ countries: [String], for rule: SmartFilterType) {
        Log.debug("countries changed, rule: \(rule), countries: \(self.selectedCountries(for: rule)) → \(countries)")
        self.persistenceManager?.setSelectedCountries(countries, for: rule)
    }


    //MARK: - Private  -
    private weak var persistenceManager: PersistenceManagerProtocol?
}
