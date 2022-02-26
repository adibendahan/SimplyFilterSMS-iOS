//
//  mock_AutomaticFilterManager.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 03/02/2022.
//

import Foundation
import XCTest
import NaturalLanguage
@testable import Simply_Filter_SMS


class mock_AutomaticFilterManager: AutomaticFilterManagerProtocol {
    
    var isAutomaticFilteringOnGetCounter = 0
    var isAutomaticFilteringOnSetCounter = 0
    var rulesGetCounter = 0
    var rulesSetCounter = 0
    var activeAutomaticFiltersTitleGetCounter = 0
    var activeAutomaticFiltersTitleSetCounter = 0
    var automaticFiltersCacheAgeGetCounter = 0
    var automaticFiltersCacheAgeSetCounter = 0
    var languagesCounter = 0
    var languageAutomaticStateCounter = 0
    var setLanguageAtumaticStateCounter = 0
    var automaticRuleStateCounter = 0
    var setAutomaticRuleStateCounter = 0
    var selectedChoiceCounter = 0
    var setSelectedChoiceCounter = 0
    var updateAutomaticFiltersIfNeededCounter = 0
    var forceUpdateAutomaticFiltersCounter = 0
    
    var isAutomaticFilteringOnClosure: (() -> (Bool))?
    var rulesClosure: (() -> ([RuleType]))?
    var activeAutomaticFiltersTitleClosure: (() -> (String?))?
    var automaticFiltersCacheAgeClosure: (() -> (Date?))?
    var languagesClosure: ((LanguageListView.Mode) -> ([NLLanguage]))?
    var languageAutomaticStateClosure: ((NLLanguage) -> (Bool))?
    var setLanguageAtumaticStateClosure: ((NLLanguage, Bool) -> ())?
    var automaticRuleStateClosure: ((RuleType) -> (Bool))?
    var setAutomaticRuleStateClosure: ((RuleType, Bool) -> ())?
    var selectedChoiceClosure: ((RuleType) -> (Int))?
    var setSelectedChoiceClosure: ((RuleType, Int) -> ())?
    var updateAutomaticFiltersIfNeededClosure: (() -> ())?
    var forceUpdateAutomaticFiltersClosure: (() -> ())?
    
    var isAutomaticFilteringOn: Bool {
        get {
            self.isAutomaticFilteringOnGetCounter += 1
            return self.isAutomaticFilteringOnClosure?() ?? false
        }
        set {
            self.isAutomaticFilteringOnSetCounter += 1
        }
    }
    
    var rules: [RuleType] {
        get {
            self.rulesGetCounter += 1
            return self.rulesClosure?() ?? []
        }
        set {
            self.rulesGetCounter += 1
        }
    }
    
    var activeAutomaticFiltersTitle: String? {
        get {
            self.activeAutomaticFiltersTitleGetCounter += 1
            return self.activeAutomaticFiltersTitleClosure?() ?? nil
        }
        set {
            self.activeAutomaticFiltersTitleGetCounter += 1
        }
    }
    
    var automaticFiltersCacheAge: Date? {
        get {
            self.automaticFiltersCacheAgeGetCounter += 1
            return self.automaticFiltersCacheAgeClosure?() ?? nil
        }
        set {
            self.automaticFiltersCacheAgeSetCounter += 1
        }
    }
    
    func languages(for type: LanguageListView.Mode) -> [NLLanguage] {
        self.languagesCounter += 1
        return self.languagesClosure?(type) ?? []
    }
    
    func languageAutomaticState(for language: NLLanguage) -> Bool {
        self.languagesCounter += 1
        return self.languageAutomaticStateClosure?(language) ?? false
    }
    
    func setLanguageAutmaticState(for language: NLLanguage, value: Bool) {
        self.setLanguageAtumaticStateCounter += 1
        self.setLanguageAtumaticStateClosure?(language, value)
    }
    
    func automaticRuleState(for rule: RuleType) -> Bool {
        self.automaticRuleStateCounter += 1
        return self.automaticRuleStateClosure?(rule) ?? false
    }
    
    func setAutomaticRuleState(for rule: RuleType, value: Bool) {
        self.setAutomaticRuleStateCounter += 1
        self.setAutomaticRuleStateClosure?(rule, value)
    }
    
    func selectedChoice(for rule: RuleType) -> Int {
        self.selectedChoiceCounter += 1
        return self.selectedChoiceClosure?(rule) ?? 0
    }
    
    func setSelectedChoice(for rule: RuleType, choice: Int) {
        self.setSelectedChoiceCounter += 1
        self.setSelectedChoiceClosure?(rule, choice)
    }
    
    func updateAutomaticFiltersIfNeeded() {
        self.updateAutomaticFiltersIfNeededCounter += 1
        self.updateAutomaticFiltersIfNeededClosure?()
    }
    
    func forceUpdateAutomaticFilters() async {
        self.forceUpdateAutomaticFiltersCounter += 1
        self.forceUpdateAutomaticFiltersClosure?()
    }
    
    func resetCounters() {
        self.isAutomaticFilteringOnGetCounter = 0
        self.isAutomaticFilteringOnSetCounter = 0
        self.rulesGetCounter = 0
        self.rulesSetCounter = 0
        self.activeAutomaticFiltersTitleGetCounter = 0
        self.activeAutomaticFiltersTitleSetCounter = 0
        self.automaticFiltersCacheAgeGetCounter = 0
        self.automaticFiltersCacheAgeSetCounter = 0
        self.languagesCounter = 0
        self.languageAutomaticStateCounter = 0
        self.setLanguageAtumaticStateCounter = 0
        self.automaticRuleStateCounter = 0
        self.setAutomaticRuleStateCounter = 0
        self.selectedChoiceCounter = 0
        self.setSelectedChoiceCounter = 0
        self.updateAutomaticFiltersIfNeededCounter = 0
        self.forceUpdateAutomaticFiltersCounter = 0
    }
}
