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

#warning("Adi - Missing implementation")
class mock_AutomaticFilterManager: AutomaticFilterManagerProtocol {
    var isAutomaticFilteringOn: Bool = false
    
    var rules: [RuleType] = []
    
    var activeAutomaticFiltersTitle: String? = nil
    
    var automaticFiltersCacheAge: Date? = nil
    
    func languages(for type: LanguageListView.Mode) -> [NLLanguage] {
        return []
    }
    
    func languageAutomaticState(for language: NLLanguage) -> Bool {
        return false
    }
    
    func setLanguageAtumaticState(for language: NLLanguage, value: Bool) {
        
    }
    
    func automaticRuleState(for rule: RuleType) -> Bool {
        return false
    }
    
    func setAutomaticRuleState(for rule: RuleType, value: Bool) {
        
    }
    
    func selectedChoice(for rule: RuleType) -> Int {
        return 0
    }
    
    func setSelectedChoice(for rule: RuleType, choice: Int) {
        
    }
    
    func fetchAutomaticFilterList(completion: @escaping (AutomaticFilterList?) -> ()) {
        
    }
    
    func forceUpdateAutomaticFilters(completion: (() -> ())?) {
        
    }
}
