//
//  FilterListLanguagesViewModelTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 21/11/2026.
//

import Foundation
import XCTest
import NaturalLanguage
@testable import Simply_Filter_SMS

class FilterListLanguagesViewModelTests: XCTestCase {

    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()
        self.filterListManager = mock_FilterListManager()
        self.appManager = mock_AppManager()
        self.appManager.filterListManager = self.filterListManager
        self.filterListManager.filterListLanguagesClosure = { [.english, .hebrew, .arabic] }
        self.filterListManager.filterListRuleCountsClosure = { [.english: 833, .hebrew: 382] }
        self.filterListManager.isFilterListActiveClosure = { $0 == .english || $0 == .hebrew }
    }


    //MARK: Tests
    func test_headline_countsActiveLanguages() {
        // Act
        let viewModel = FilterListLanguagesView.ViewModel(appManager: self.appManager)

        // Verify
        XCTAssertEqual(viewModel.activeLanguagesCount, 2)
        XCTAssertEqual(viewModel.headline, String.localizedStringWithFormat("autoFilter_languagesOn"~, 2))
    }

    func test_badgeTitle_splitsAroundTheNumber() {
        // Act
        let viewModel = FilterListLanguagesView.ViewModel(appManager: self.appManager)

        // Verify
        let title = viewModel.badgeTitle
        XCTAssertEqual(title.number, String.localizedStringWithFormat("%ld", 2))
        XCTAssertEqual(title.text, viewModel.headline)
    }

    func test_badgeTitle_noLanguages_isOnePart() {
        // Prepare
        self.filterListManager.isFilterListActiveClosure = { _ in false }

        // Act
        let viewModel = FilterListLanguagesView.ViewModel(appManager: self.appManager)

        // Verify
        XCTAssertEqual(viewModel.badgeTitle.prefix, viewModel.headline)
        XCTAssertEqual(viewModel.badgeTitle.number, "")
        XCTAssertEqual(viewModel.badgeOffTitle, viewModel.headline)
    }

    func test_footer_sumsRulesOfActiveLanguages() {
        // Act
        let viewModel = FilterListLanguagesView.ViewModel(appManager: self.appManager)

        // Verify
        XCTAssertEqual(viewModel.footer, String.localizedStringWithFormat("autoFilter_rulesFromLanguages"~, 1215, 2))
    }

    func test_footer_noActiveLanguages_asksToTurnOneOn() {
        // Prepare
        self.filterListManager.isFilterListActiveClosure = { _ in false }

        // Act
        let viewModel = FilterListLanguagesView.ViewModel(appManager: self.appManager)

        // Verify
        XCTAssertEqual(viewModel.activeLanguagesCount, 0)
        XCTAssertEqual(viewModel.footer, "autoFilter_turnOnHint"~)
    }

    func test_footer_endsWithLastUpdated() {
        // Prepare
        let lastUpdated = Date(timeIntervalSince1970: 1_800_000_000)
        self.filterListManager.filterListsLastUpdatedClosure = { lastUpdated }

        // Act
        let viewModel = FilterListLanguagesView.ViewModel(appManager: self.appManager)

        // Verify
        XCTAssertTrue(viewModel.footer.hasSuffix(". " + lastUpdated.lastUpdatedText))
    }

    func test_toggle_updatesHeadlineAndFooter() {
        // Prepare
        let viewModel = FilterListLanguagesView.ViewModel(appManager: self.appManager)

        // Act
        viewModel.languages[1].state = false

        // Verify
        XCTAssertEqual(self.filterListManager.setFilterListActiveCounter, 1)
        XCTAssertEqual(viewModel.activeLanguagesCount, 1)
        XCTAssertEqual(viewModel.footer, String.localizedStringWithFormat("autoFilter_rulesFromLanguages"~, 833, 1))
    }

    func test_ruleCountTexts_onlyForDownloadedLists() {
        // Act
        let viewModel = FilterListLanguagesView.ViewModel(appManager: self.appManager)

        // Verify
        XCTAssertEqual(viewModel.ruleCountTexts[.hebrew], String.localizedStringWithFormat("autoFilter_ruleCount"~, 382))
        XCTAssertEqual(viewModel.ruleCountTexts[.english], String.localizedStringWithFormat("autoFilter_ruleCount"~, 833))
        XCTAssertNil(viewModel.ruleCountTexts[.arabic])
    }

    func test_nativeNames_hiddenWhenSameAsPhoneLanguage() {
        // Act
        let viewModel = FilterListLanguagesView.ViewModel(appManager: self.appManager)

        // Verify
        let expectedHebrewName: String?
        if NLLanguage.hebrew.nativeName == NLLanguage.hebrew.localizedName {
            expectedHebrewName = nil
        }
        else {
            expectedHebrewName = "עברית"
        }
        XCTAssertEqual(viewModel.nativeNames[.hebrew], expectedHebrewName)
    }

    //MARK: Private
    private var filterListManager = mock_FilterListManager()
    private var appManager = mock_AppManager()
}
