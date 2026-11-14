//
//  CommunityListsViewModelTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 12/11/2026.
//

import Foundation
import XCTest
@testable import Simply_Filter_SMS

class CommunityListsViewModelTests: XCTestCase {

    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()
        self.filterListManager = mock_FilterListManager()
        self.appManager = mock_AppManager()
        self.appManager.filterListManager = self.filterListManager
        self.filterListManager.communityListsClosure = { [self.curatedList, self.userList] }
    }


    //MARK: Tests
    func test_lists_comeFromTheManager() {
        // Act
        let viewModel = CommunityListsView.ViewModel(appManager: self.appManager)

        // Verify
        XCTAssertEqual(viewModel.rowViewModels.map(\.id), [self.curatedList.url, self.userList.url])
        XCTAssertEqual(viewModel.rowViewModels.map(\.isActive), [false, true])
    }

    func test_toggle_setsTheListActive() {
        // Prepare
        let viewModel = CommunityListsView.ViewModel(appManager: self.appManager)
        var changes: [(String, Bool)] = []
        self.filterListManager.setCommunityListActiveClosure = { communityList, value in
            changes.append((communityList.url, value))
        }

        // Act
        viewModel.rowViewModels[0].updateCommunityList(isActive: true)

        // Verify
        XCTAssertEqual(changes.map(\.0), [self.curatedList.url])
        XCTAssertEqual(changes.map(\.1), [true])
    }

    func test_refresh_keepsRowViewModelsByID() {
        // Prepare
        let viewModel = CommunityListsView.ViewModel(appManager: self.appManager)
        let curatedRow = viewModel.rowViewModels[0]
        let switchedOn = CommunityListItem(url: self.curatedList.url, name: self.curatedList.name, description: nil, homepage: nil,
                                           locale: nil, cacheSection: nil, isActive: true, isCurated: true)
        self.filterListManager.communityListsClosure = { [switchedOn] }

        // Act
        viewModel.refresh()

        // Verify
        XCTAssertTrue(viewModel.rowViewModels[0] === curatedRow)
        XCTAssertTrue(curatedRow.isActive)
        XCTAssertEqual(viewModel.rowViewModels.count, 1)
    }

    func test_remove_skipsCuratedLists() {
        // Prepare
        let viewModel = CommunityListsView.ViewModel(appManager: self.appManager)
        var removedURLs: [String] = []
        self.filterListManager.removeCommunityListClosure = { removedURLs.append($0.url) }

        // Act
        viewModel.removeCommunityLists(at: IndexSet([0, 1]))

        // Verify
        XCTAssertEqual(removedURLs, [self.userList.url])
    }

    func test_addList_presentsAFreshSheet() {
        // Prepare
        let viewModel = CommunityListsView.ViewModel(appManager: self.appManager)

        // Act
        viewModel.presentAddCommunityList()

        // Verify
        XCTAssertNotNil(viewModel.addCommunityListViewModel)
        XCTAssertEqual(viewModel.addCommunityListViewModel?.previewState, .empty)
    }

    func test_addListPreview_loadsTheList() async {
        // Prepare
        let viewModel = self.makeAddListViewModel()
        self.filterListManager.previewCommunityListClosure = { _ in .success(self.previewedList) }

        // Act
        viewModel.urlText = self.previewedList.url
        await self.waitForPreview(viewModel)

        // Verify
        XCTAssertEqual(viewModel.previewState, .loaded(self.previewedList))
        XCTAssertTrue(viewModel.canSubscribe)
    }

    func test_addListPreview_groupsTheFiltersByType() async {
        // Prepare
        let viewModel = self.makeAddListViewModel()
        let denyLoan = FilterExportRecord(text: "loan", type: "deny", folder: "junk", target: "body", matching: "contains", caseSensitivity: "insensitive")
        let denyPrize = FilterExportRecord(text: "prize", type: "deny", folder: "junk", target: "body", matching: "contains", caseSensitivity: "insensitive")
        let allowBank = FilterExportRecord(text: "MyBank", type: "allow", folder: nil, target: "sender", matching: "exact", caseSensitivity: "insensitive")
        let invalid = FilterExportRecord(text: "   ", type: "deny", folder: "junk", target: "body", matching: "contains", caseSensitivity: "insensitive")
        let payload = FilterExportPayload(format: FilterExportPayload.formatIdentifier,
                                          version: FilterExportPayload.currentVersion,
                                          exportedAt: Date(),
                                          appVersion: "4.0.0",
                                          name: "New",
                                          revision: nil,
                                          description: nil,
                                          homepage: nil,
                                          locale: "he-IL",
                                          filters: [denyLoan, allowBank, denyPrize, invalid],
                                          forceClearBeforeImport: nil)
        let section = FilterListsCacheSection(url: self.previewedList.url, etag: nil, payload: payload)
        let listWithFilters = CommunityListItem(url: self.previewedList.url,
                                                name: "New",
                                                description: nil,
                                                homepage: nil,
                                                locale: Locale(identifier: "he-IL"),
                                                cacheSection: section,
                                                isActive: false,
                                                isCurated: false)
        self.filterListManager.previewCommunityListClosure = { _ in .success(listWithFilters) }

        // Act
        viewModel.urlText = listWithFilters.url
        await self.waitForPreview(viewModel)

        // Verify
        XCTAssertTrue(viewModel.isLoaded)
        XCTAssertEqual(viewModel.filterTypes, [.allow, .deny])
        XCTAssertEqual(viewModel.candidates(for: .deny).map(\.text), ["loan", "prize"])
        XCTAssertEqual(viewModel.candidates(for: .allow).map(\.text), ["MyBank"])
    }

    func test_addListPreview_showsTheError() async {
        // Prepare
        let viewModel = self.makeAddListViewModel()
        self.filterListManager.previewCommunityListClosure = { _ in .failure(.invalidLocale) }

        // Act
        viewModel.urlText = "https://lists.example.com/nolocale.sfsfilters"
        await self.waitForPreview(viewModel)

        // Verify
        XCTAssertEqual(viewModel.previewState, .failed(.invalidLocale))
        XCTAssertFalse(viewModel.canSubscribe)
    }

    func test_addListPreview_emptyTextClearsIt() async {
        // Prepare
        let viewModel = self.makeAddListViewModel()
        self.filterListManager.previewCommunityListClosure = { _ in .success(self.previewedList) }
        viewModel.urlText = self.previewedList.url
        await self.waitForPreview(viewModel)

        // Act
        viewModel.urlText = "   "

        // Verify
        XCTAssertEqual(viewModel.previewState, .empty)
        XCTAssertFalse(viewModel.canSubscribe)
    }

    @MainActor
    func test_subscribe_passesThePreviewedList() async {
        // Prepare
        let viewModel = self.makeAddListViewModel()
        var subscribedURLs: [String] = []
        self.filterListManager.previewCommunityListClosure = { _ in .success(self.previewedList) }
        self.filterListManager.subscribeCommunityListClosure = { communityList in
            subscribedURLs.append(communityList.url)
            return true
        }
        viewModel.urlText = self.previewedList.url
        await self.waitForPreview(viewModel)

        // Act
        let isSubscribed = await viewModel.subscribe()

        // Verify
        XCTAssertTrue(isSubscribed)
        XCTAssertEqual(subscribedURLs, [self.previewedList.url])
        XCTAssertFalse(viewModel.didFailToSubscribe)
    }

    @MainActor
    func test_subscribe_failureIsShown() async {
        // Prepare
        let viewModel = self.makeAddListViewModel()
        self.filterListManager.previewCommunityListClosure = { _ in .success(self.previewedList) }
        self.filterListManager.subscribeCommunityListClosure = { _ in false }
        viewModel.urlText = self.previewedList.url
        await self.waitForPreview(viewModel)

        // Act
        let isSubscribed = await viewModel.subscribe()

        // Verify
        XCTAssertFalse(isSubscribed)
        XCTAssertTrue(viewModel.didFailToSubscribe)
    }

    @MainActor
    func test_subscribe_withoutAPreview_doesNothing() async {
        // Prepare
        let viewModel = self.makeAddListViewModel()

        // Act
        let isSubscribed = await viewModel.subscribe()

        // Verify
        XCTAssertFalse(isSubscribed)
        XCTAssertEqual(self.filterListManager.subscribeCommunityListCounter, 0)
    }


    func test_localeLabel_showsTheFlagOnlyWithARegion() {
        // Prepare
        let withRegion = self.curatedList
        let withoutRegion = CommunityListItem(url: self.userURL, name: "Mine", description: nil, homepage: nil,
                                              locale: Locale(identifier: "he"), cacheSection: nil, isActive: false, isCurated: false)

        // Act
        let regionLabel = withRegion.localeLabel
        let languageLabel = withoutRegion.localeLabel

        // Verify
        XCTAssertEqual(Locale.Region("US").flagEmoji, "🇺🇸")
        XCTAssertEqual(Locale.Region("IL").flagEmoji, "🇮🇱")
        XCTAssertNil(Locale.Region("419").flagEmoji)
        XCTAssertEqual(regionLabel?.hasPrefix("🇺🇸 "), true)
        XCTAssertEqual(languageLabel, Locale.current.localizedString(forLanguageCode: "he")?.localizedCapitalized)
        XCTAssertNil(self.userList.localeLabel)
    }


    //MARK: Private Variables and Helpers
    private var appManager: mock_AppManager!
    private var filterListManager: mock_FilterListManager!

    private let curatedList = CommunityListItem(url: "https://lists.example.com/curated.sfsfilters",
                                                name: "Curated",
                                                description: "Blocks scams",
                                                homepage: URL(string: "https://example.com"),
                                                locale: Locale(identifier: "en-US"),
                                                cacheSection: nil,
                                                isActive: false,
                                                isCurated: true)

    private let userURL = "https://lists.example.com/mine.sfsfilters"

    private let userList = CommunityListItem(url: "https://lists.example.com/mine.sfsfilters",
                                             name: "Mine",
                                             description: nil,
                                             homepage: nil,
                                             locale: nil,
                                             cacheSection: nil,
                                             isActive: true,
                                             isCurated: false)

    private let previewedList = CommunityListItem(url: "https://lists.example.com/new.sfsfilters",
                                                  name: "New",
                                                  description: nil,
                                                  homepage: nil,
                                                  locale: Locale(identifier: "he-IL"),
                                                  cacheSection: nil,
                                                  isActive: false,
                                                  isCurated: false)

    private func makeAddListViewModel() -> AddCommunityListView.ViewModel {
        return AddCommunityListView.ViewModel(previewDelay: .zero, appManager: self.appManager)
    }

    private func waitForPreview(_ viewModel: AddCommunityListView.ViewModel) async {
        for _ in 0..<200 {
            switch viewModel.previewState {
            case .loaded, .failed:
                return
            case .empty, .loading:
                try? await Task.sleep(for: .milliseconds(10))
            }
        }
        XCTFail("preview never finished")
    }
}
