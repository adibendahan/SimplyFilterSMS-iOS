//
//  SmartFilterManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 07/11/2026.
//

import Foundation

protocol SmartFilterManagerProtocol {
    var rules: [RuleType] { get }

    func ruleState(for rule: RuleType) -> Bool
    func setRuleState(for rule: RuleType, value: Bool)
    func selectedChoice(for rule: RuleType) -> Int
    func setSelectedChoice(for rule: RuleType, choice: Int)
    func selectedCountries(for rule: RuleType) -> [String]
    func setSelectedCountries(_ countries: [String], for rule: RuleType)
}
