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

    var smartFilterTypesGetCounter = 0
    var isSmartFilterActiveCounter = 0
    var setSmartFilterActiveCounter = 0
    var selectedChoiceCounter = 0
    var setSelectedChoiceCounter = 0
    var selectedCountriesCounter = 0
    var setSelectedCountriesCounter = 0

    var smartFilterTypesClosure: (() -> ([SmartFilterType]))?
    var isSmartFilterActiveClosure: ((SmartFilterType) -> (Bool))?
    var setSmartFilterActiveClosure: ((SmartFilterType, Bool) -> ())?
    var selectedChoiceClosure: ((SmartFilterType) -> (Int))?
    var setSelectedChoiceClosure: ((SmartFilterType, Int) -> ())?
    var selectedCountriesClosure: ((SmartFilterType) -> ([String]))?
    var setSelectedCountriesClosure: (([String], SmartFilterType) -> ())?

    var smartFilterTypes: [SmartFilterType] {
        self.smartFilterTypesGetCounter += 1
        return self.smartFilterTypesClosure?() ?? []
    }

    func isSmartFilterActive(for rule: SmartFilterType) -> Bool {
        self.isSmartFilterActiveCounter += 1
        return self.isSmartFilterActiveClosure?(rule) ?? false
    }

    func setSmartFilterActive(for rule: SmartFilterType, value: Bool) {
        self.setSmartFilterActiveCounter += 1
        self.setSmartFilterActiveClosure?(rule, value)
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
        self.smartFilterTypesGetCounter = 0
        self.isSmartFilterActiveCounter = 0
        self.setSmartFilterActiveCounter = 0
        self.selectedChoiceCounter = 0
        self.setSelectedChoiceCounter = 0
        self.selectedCountriesCounter = 0
        self.setSelectedCountriesCounter = 0
    }
}
