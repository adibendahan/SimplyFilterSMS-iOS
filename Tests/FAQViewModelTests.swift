//
//  FAQViewModelTests.swift
//  Tests
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class FAQViewModelTests: XCTestCase {

    private func makeViewModel() -> FAQView.ViewModel {
        return FAQView.ViewModel(appManager: mock_AppManager())
    }

    func test_emptySearch_showsAllQuestions() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.visibleItems, HelpFAQ.allCases)
        vm.searchQuery = "   "
        XCTAssertEqual(vm.visibleItems, HelpFAQ.allCases)
    }

    func test_search_matchesQuestion() {
        let vm = makeViewModel()
        vm.searchQuery = HelpFAQ.communityLists.question
        XCTAssertTrue(vm.visibleItems.contains(.communityLists))
        XCTAssertLessThan(vm.visibleItems.count, HelpFAQ.allCases.count)
    }

    func test_search_matchesAnswerWithoutBoldMarkers() {
        let vm = makeViewModel()
        let answer = HelpFAQ.smartFilters.answer.replacingOccurrences(of: "**", with: "")
        vm.searchQuery = String(answer.prefix(30))
        XCTAssertTrue(vm.visibleItems.contains(.smartFilters))
    }

    func test_search_withNoMatch_isEmpty() {
        let vm = makeViewModel()
        vm.searchQuery = "zzqqxxnomatch"
        XCTAssertTrue(vm.visibleItems.isEmpty)
    }

    func test_search_expandsEveryResult() {
        let vm = makeViewModel()
        vm.setExpanded(.privacy, open: true)
        vm.searchQuery = HelpFAQ.communityLists.question
        XCTAssertEqual(vm.expandedFAQs, Set(vm.visibleItems))
    }

    func test_search_resultsCollapseOneByOne() {
        let vm = makeViewModel()
        vm.searchQuery = "a"
        let first = try! XCTUnwrap(vm.visibleItems.first)
        vm.setExpanded(first, open: false)
        XCTAssertFalse(vm.expandedFAQs.contains(first))
        XCTAssertEqual(vm.expandedFAQs.count, vm.visibleItems.count - 1)
        vm.setExpanded(first, open: true)
        XCTAssertEqual(vm.expandedFAQs, Set(vm.visibleItems))
    }

    func test_clearingSearch_collapsesAll() {
        let vm = makeViewModel()
        vm.searchQuery = "a"
        vm.searchQuery = ""
        XCTAssertTrue(vm.expandedFAQs.isEmpty)
    }

    func test_withoutSearch_opensOneAnswerAtATime() {
        let vm = makeViewModel()
        vm.setExpanded(.privacy, open: true)
        vm.setExpanded(.folders, open: true)
        XCTAssertEqual(vm.expandedFAQs, [.folders])
    }

    func test_highlighting_marksEveryMatchIgnoringCase() {
        let text = AttributedString("Junk goes to junk.").highlighting("JUNK")
        let highlighted = text.runs.filter { $0.backgroundColor != nil }
        let words = highlighted.map { String(text[$0.range].characters) }
        XCTAssertEqual(words, ["Junk", "junk"])
    }

    func test_highlighting_emptyQueryChangesNothing() {
        let text = AttributedString("Junk").highlighting("")
        XCTAssertTrue(text.runs.allSatisfy { $0.backgroundColor == nil })
    }
}
