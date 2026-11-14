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
    var filterListLanguagesGetCounter = 0
    var isFilterListActiveCounter = 0
    var setFilterListActiveCounter = 0
    var refreshFilterListsCounter = 0
    var updateFilterListsWhenOnlineCounter = 0
    var communityListsGetCounter = 0
    var activeCommunityListsCountGetCounter = 0
    var setCommunityListActiveCounter = 0
    var removeCommunityListCounter = 0
    var previewCommunityListCounter = 0
    var subscribeCommunityListCounter = 0
    
    var hasActiveFilterListsClosure: (() -> (Bool))?
    var onFilterListsUpdateFinishedCounter = 0
    var onFilterListsUpdateFinishedClosure: ((@escaping () -> Void) -> ())?
    var activeFilterListsTitleClosure: (() -> (String?))?
    var filterListsLastUpdatedClosure: (() -> (Date?))?
    var filterListLanguagesClosure: (() -> ([NLLanguage]))?
    var isFilterListActiveClosure: ((NLLanguage) -> (Bool))?
    var setFilterListActiveClosure: ((NLLanguage, Bool) -> ())?
    var refreshFilterListsClosure: (() -> ())?
    var updateFilterListsWhenOnlineClosure: (() -> ())?
    var communityListsClosure: (() -> ([CommunityListItem]))?
    var activeCommunityListsCountClosure: (() -> (Int))?
    var setCommunityListActiveClosure: ((CommunityListItem, Bool) -> ())?
    var removeCommunityListClosure: ((CommunityListItem) -> ())?
    var previewCommunityListClosure: ((URL) async -> (Result<CommunityListItem, CommunityListPreviewError>))?
    var subscribeCommunityListClosure: ((CommunityListItem) -> (Bool))?
    
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
    
    var filterListLanguages: [NLLanguage] {
        self.filterListLanguagesGetCounter += 1
        return self.filterListLanguagesClosure?() ?? []
    }
    
    var communityLists: [CommunityListItem] {
        self.communityListsGetCounter += 1
        return self.communityListsClosure?() ?? []
    }

    var activeCommunityListsCount: Int {
        self.activeCommunityListsCountGetCounter += 1
        return self.activeCommunityListsCountClosure?() ?? 0
    }

    func setCommunityListActive(_ communityList: CommunityListItem, value: Bool) {
        self.setCommunityListActiveCounter += 1
        self.setCommunityListActiveClosure?(communityList, value)
    }

    func removeCommunityList(_ communityList: CommunityListItem) {
        self.removeCommunityListCounter += 1
        self.removeCommunityListClosure?(communityList)
    }

    func previewCommunityList(at url: URL) async -> Result<CommunityListItem, CommunityListPreviewError> {
        self.previewCommunityListCounter += 1
        return await self.previewCommunityListClosure?(url) ?? .failure(.notAList)
    }

    func subscribeCommunityList(_ communityList: CommunityListItem) async -> Bool {
        self.subscribeCommunityListCounter += 1
        return self.subscribeCommunityListClosure?(communityList) ?? false
    }

    func isFilterListActive(for language: NLLanguage) -> Bool {
        self.isFilterListActiveCounter += 1
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
        self.filterListLanguagesGetCounter = 0
        self.isFilterListActiveCounter = 0
        self.setFilterListActiveCounter = 0
        self.refreshFilterListsCounter = 0
        self.updateFilterListsWhenOnlineCounter = 0
        self.onFilterListsUpdateFinishedCounter = 0
        self.communityListsGetCounter = 0
        self.activeCommunityListsCountGetCounter = 0
        self.setCommunityListActiveCounter = 0
        self.removeCommunityListCounter = 0
        self.previewCommunityListCounter = 0
        self.subscribeCommunityListCounter = 0
    }

    func onFilterListsUpdateFinished(_ handler: @escaping () -> Void) {
        self.onFilterListsUpdateFinishedCounter += 1
        guard let onFilterListsUpdateFinishedClosure = self.onFilterListsUpdateFinishedClosure else {
            handler()
            return
        }
        onFilterListsUpdateFinishedClosure(handler)
    }
}
