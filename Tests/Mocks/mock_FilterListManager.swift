//
//  mock_FilterListManager.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 03/02/2022.
//

import Foundation
import XCTest
import NaturalLanguage
@testable import Simply_Filter_SMS


class mock_FilterListManager: FilterListManagerProtocol {
    
    var hasActiveFilterListsGetCounter = 0
    var hasActiveFilterListsSetCounter = 0
    var activeFilterListsTitleGetCounter = 0
    var activeFilterListsTitleSetCounter = 0
    var filterListsLastUpdatedGetCounter = 0
    var filterListsLastUpdatedSetCounter = 0
    var languagesCounter = 0
    var isFilterListActiveCounter = 0
    var setFilterListActiveCounter = 0
    var refreshFilterListsCounter = 0
    var updateFilterListsWhenOnlineCounter = 0
    
    var hasActiveFilterListsClosure: (() -> (Bool))?
    var activeFilterListsTitleClosure: (() -> (String?))?
    var filterListsLastUpdatedClosure: (() -> (Date?))?
    var languagesClosure: ((LanguageListView.Mode) -> ([NLLanguage]))?
    var isFilterListActiveClosure: ((NLLanguage) -> (Bool))?
    var setFilterListActiveClosure: ((NLLanguage, Bool) -> ())?
    var refreshFilterListsClosure: (() -> ())?
    var updateFilterListsWhenOnlineClosure: (() -> ())?
    
    var hasActiveFilterLists: Bool {
        get {
            self.hasActiveFilterListsGetCounter += 1
            return self.hasActiveFilterListsClosure?() ?? false
        }
        set {
            self.hasActiveFilterListsSetCounter += 1
        }
    }
    
    var activeFilterListsTitle: String? {
        get {
            self.activeFilterListsTitleGetCounter += 1
            return self.activeFilterListsTitleClosure?() ?? nil
        }
        set {
            self.activeFilterListsTitleSetCounter += 1
        }
    }
    
    var filterListsLastUpdated: Date? {
        get {
            self.filterListsLastUpdatedGetCounter += 1
            return self.filterListsLastUpdatedClosure?() ?? nil
        }
        set {
            self.filterListsLastUpdatedSetCounter += 1
        }
    }
    
    func languages(for type: LanguageListView.Mode) -> [NLLanguage] {
        self.languagesCounter += 1
        return self.languagesClosure?(type) ?? []
    }
    
    func isFilterListActive(for language: NLLanguage) -> Bool {
        self.languagesCounter += 1
        return self.isFilterListActiveClosure?(language) ?? false
    }
    
    func setFilterListActive(for language: NLLanguage, value: Bool) {
        self.setFilterListActiveCounter += 1
        self.setFilterListActiveClosure?(language, value)
    }
    
    func refreshFilterLists() async {
        self.refreshFilterListsCounter += 1
        self.refreshFilterListsClosure?()
    }
    
    @MainActor
    func updateFilterListsWhenOnline() {
        self.updateFilterListsWhenOnlineCounter += 1
        self.updateFilterListsWhenOnlineClosure?()
    }
    
    func resetCounters() {
        self.hasActiveFilterListsGetCounter = 0
        self.hasActiveFilterListsSetCounter = 0
        self.activeFilterListsTitleGetCounter = 0
        self.activeFilterListsTitleSetCounter = 0
        self.filterListsLastUpdatedGetCounter = 0
        self.filterListsLastUpdatedSetCounter = 0
        self.languagesCounter = 0
        self.isFilterListActiveCounter = 0
        self.setFilterListActiveCounter = 0
        self.refreshFilterListsCounter = 0
        self.updateFilterListsWhenOnlineCounter = 0
    }
}
