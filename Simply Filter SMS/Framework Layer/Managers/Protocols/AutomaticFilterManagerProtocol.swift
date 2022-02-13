//
//  AutomaticFilterManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 30/01/2022.
//

import Foundation
import NaturalLanguage

protocol AutomaticFilterManagerProtocol {
    var isAutomaticFilteringOn: Bool { get }
    var rules: [RuleType] { get }
    var activeAutomaticFiltersTitle: String? { get }
    var automaticFiltersCacheAge: Date? { get }
    
    func languages(for type: LanguageListView.Mode) -> [NLLanguage]
    func languageAutomaticState(for language: NLLanguage) -> Bool
    func setLanguageAutmaticState(for language: NLLanguage, value: Bool)
    func automaticRuleState(for rule: RuleType) -> Bool
    func setAutomaticRuleState(for rule: RuleType, value: Bool)
    func selectedChoice(for rule: RuleType) -> Int
    func setSelectedChoice(for rule: RuleType, choice: Int)
    func forceUpdateAutomaticFilters() async
}
