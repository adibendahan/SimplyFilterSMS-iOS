//
//  AddFilterViewModelTests.swift
//  Simply Filter SMS Tests
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class AddFilterViewModelTests: XCTestCase {

    private var appManager = mock_AppManager()

    override func setUp() {
        super.setUp()
        let appManager = mock_AppManager()
        let persistanceManager = mock_PersistanceManager()
        let defaultsManager = mock_DefaultsManager()
        let automaticFilterManager = mock_AutomaticFilterManager()
        appManager.persistanceManager = persistanceManager
        appManager.defaultsManager = defaultsManager
        appManager.automaticFilterManager = automaticFilterManager
        self.appManager = appManager
    }

    private func makeViewModel() -> AddFilterView.ViewModel {
        AddFilterView.ViewModel(filterType: .deny, appManager: appManager)
    }

    // MARK: isInvalidRegex tests

    func test_isInvalidRegex_falseWhenNotRegexMatching() {
        let vm = makeViewModel()
        vm.selectedFilterMatching = .contains
        vm.filterText = "[unclosed"
        XCTAssertFalse(vm.isInvalidRegex, "isInvalidRegex should be false when matching is not .regex")
    }

    func test_isInvalidRegex_falseWhenEmpty() {
        let vm = makeViewModel()
        vm.selectedFilterMatching = .regex
        vm.filterText = ""
        XCTAssertFalse(vm.isInvalidRegex, "isInvalidRegex should be false when filterText is empty")
    }

    func test_isInvalidRegex_trueForInvalidPattern() {
        let vm = makeViewModel()
        vm.selectedFilterMatching = .regex
        vm.filterText = "[unclosed"
        XCTAssertTrue(vm.isInvalidRegex, "isInvalidRegex should be true for invalid regex pattern")
    }

    func test_isInvalidRegex_falseForValidPattern() {
        let vm = makeViewModel()
        vm.selectedFilterMatching = .regex
        vm.filterText = #"\d{5}"#
        XCTAssertFalse(vm.isInvalidRegex, "isInvalidRegex should be false for valid regex pattern")
    }

    // MARK: regexTestResult tests

    func test_regexTestResult_emptyWhenNotRegex() {
        let vm = makeViewModel()
        vm.selectedFilterMatching = .contains
        vm.filterText = #"\d+"#
        vm.regexTestText = "123"
        XCTAssertEqual(vm.regexTestResult, .empty, "regexTestResult should be .empty when matching is not .regex")
    }

    func test_regexTestResult_emptyWhenTestTextEmpty() {
        let vm = makeViewModel()
        vm.selectedFilterMatching = .regex
        vm.filterText = #"\d+"#
        vm.regexTestText = ""
        XCTAssertEqual(vm.regexTestResult, .empty, "regexTestResult should be .empty when regexTestText is empty")
    }

    func test_regexTestResult_invalidPatternForBadRegex() {
        let vm = makeViewModel()
        vm.selectedFilterMatching = .regex
        vm.filterText = "[unclosed"
        vm.regexTestText = "hello"
        XCTAssertEqual(vm.regexTestResult, .invalidPattern, "regexTestResult should be .invalidPattern for bad regex")
    }

    func test_regexTestResult_matchWhenPatternMatches() {
        let vm = makeViewModel()
        vm.selectedFilterMatching = .regex
        vm.filterText = #"\d{5}"#
        vm.regexTestText = "code 12345"
        XCTAssertEqual(vm.regexTestResult, .match, "regexTestResult should be .match when pattern matches test text")
    }

    func test_regexTestResult_noMatchWhenPatternDoesNotMatch() {
        let vm = makeViewModel()
        vm.selectedFilterMatching = .regex
        vm.filterText = #"\d{5}"#
        vm.regexTestText = "hello world"
        XCTAssertEqual(vm.regexTestResult, .noMatch, "regexTestResult should be .noMatch when pattern does not match test text")
    }
}
