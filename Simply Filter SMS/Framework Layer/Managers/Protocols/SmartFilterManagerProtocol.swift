//
//  SmartFilterManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 07/11/2026.
//

import Foundation

protocol SmartFilterManagerProtocol {
    var rules: [SmartFilterType] { get }

    func ruleState(for rule: SmartFilterType) -> Bool
    func setRuleState(for rule: SmartFilterType, value: Bool)
    func selectedChoice(for rule: SmartFilterType) -> Int
    func setSelectedChoice(for rule: SmartFilterType, choice: Int)
    func selectedCountries(for rule: SmartFilterType) -> [String]
    func setSelectedCountries(_ countries: [String], for rule: SmartFilterType)
}
