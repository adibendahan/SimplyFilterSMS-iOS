//
//  mock_SmartFilterManager.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 07/11/2026.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS


class mock_SmartFilterManager: SmartFilterManagerProtocol {

    var rulesGetCounter = 0
    var ruleStateCounter = 0
    var setRuleStateCounter = 0
    var selectedChoiceCounter = 0
    var setSelectedChoiceCounter = 0
    var selectedCountriesCounter = 0
    var setSelectedCountriesCounter = 0

    var rulesClosure: (() -> ([SmartFilterType]))?
    var ruleStateClosure: ((SmartFilterType) -> (Bool))?
    var setRuleStateClosure: ((SmartFilterType, Bool) -> ())?
    var selectedChoiceClosure: ((SmartFilterType) -> (Int))?
    var setSelectedChoiceClosure: ((SmartFilterType, Int) -> ())?
    var selectedCountriesClosure: ((SmartFilterType) -> ([String]))?
    var setSelectedCountriesClosure: (([String], SmartFilterType) -> ())?

    var rules: [SmartFilterType] {
        self.rulesGetCounter += 1
        return self.rulesClosure?() ?? []
    }

    func ruleState(for rule: SmartFilterType) -> Bool {
        self.ruleStateCounter += 1
        return self.ruleStateClosure?(rule) ?? false
    }

    func setRuleState(for rule: SmartFilterType, value: Bool) {
        self.setRuleStateCounter += 1
        self.setRuleStateClosure?(rule, value)
    }

    func selectedChoice(for rule: SmartFilterType) -> Int {
        self.selectedChoiceCounter += 1
        return self.selectedChoiceClosure?(rule) ?? 0
    }

    func setSelectedChoice(for rule: SmartFilterType, choice: Int) {
        self.setSelectedChoiceCounter += 1
        self.setSelectedChoiceClosure?(rule, choice)
    }

    func selectedCountries(for rule: SmartFilterType) -> [String] {
        self.selectedCountriesCounter += 1
        return self.selectedCountriesClosure?(rule) ?? []
    }

    func setSelectedCountries(_ countries: [String], for rule: SmartFilterType) {
        self.setSelectedCountriesCounter += 1
        self.setSelectedCountriesClosure?(countries, rule)
    }

    func resetCounters() {
        self.rulesGetCounter = 0
        self.ruleStateCounter = 0
        self.setRuleStateCounter = 0
        self.selectedChoiceCounter = 0
        self.setSelectedChoiceCounter = 0
        self.selectedCountriesCounter = 0
        self.setSelectedCountriesCounter = 0
    }
}
