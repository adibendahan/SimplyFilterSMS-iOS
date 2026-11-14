//
//  CommunityListsTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 12/11/2026.
//

import Foundation
import XCTest
import NaturalLanguage
import IdentityLookup
@testable import Simply_Filter_SMS

class CommunityListsTests: XCTestCase {

    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()
        self.persistenceManager = PersistenceManager(inMemory: true)
        self.filterListService = mock_FilterListService()
        self.networkSyncManager = mock_NetworkSyncManager()
        self.networkSyncManager.networkStatusClosure = { .online }
        self.filterListManager = FilterListManager(persistenceManager: self.persistenceManager,
                                                   filterListService: self.filterListService,
                                                   networkSyncManager: self.networkSyncManager)
        self.messageEvaluationManager = MessageEvaluationManager(persistenceManager: self.persistenceManager)
        self.catalogEntries = []
        self.listsByURL = [:]
        self.filterListService.fetchFilterListCatalogClosure = { _ in
            let catalog = FilterListCatalogResponse(format: FilterListCatalogResponse.formatIdentifier,
                                                    version: FilterListCatalogResponse.currentVersion,
                                                    lists: self.catalogEntries)
            return .modified(catalog, etag: nil)
        }
        self.filterListService.fetchFilterListClosure = { url, _ in
            guard let payload = self.listsByURL[url.absoluteString] else { return nil }
            return .modified(payload, etag: "\(url.lastPathComponent)-1")
        }
    }


    //MARK: Tests
    @MainActor
    func test_curatedEntry_startsOff() async {
        // Prepare
        self.catalogEntries = [self.curatedEntry]
        self.listsByURL[self.curatedURL] = self.payload(name: "Scam Guard", filters: [self.denyRecord("loan")])

        // Act
        await self.filterListManager.refreshFilterLists()

        // Verify
        let communityLists = self.filterListManager.communityLists
        XCTAssertEqual(communityLists.map(\.url), [self.curatedURL])
        XCTAssertEqual(communityLists.first?.name, "Scam Guard")
        XCTAssertEqual(communityLists.first?.description, "Blocks scams")
        XCTAssertEqual(communityLists.first?.homepage, URL(string: "https://example.com"))
        XCTAssertEqual(communityLists.first?.isCurated, true)
        XCTAssertEqual(communityLists.first?.isActive, false)
        XCTAssertEqual(communityLists.first?.locale?.identifier, "en-US", "the catalog's locale beats the file's")
        XCTAssertTrue(self.filterListManager.filterListLanguages.isEmpty, "a Community List isn't an AI Filtering language")
        XCTAssertEqual(self.evaluate(body: "fast loan").action, .allow)

        self.filterListManager.setCommunityListActive(self.communityList(self.curatedURL), value: true)
        XCTAssertEqual(self.filterListManager.activeCommunityListsCount, 1)
        XCTAssertEqual(self.evaluate(body: "fast loan").match, .filterList("Scam Guard"))
    }

    @MainActor
    func test_subscribe_downloadsAndAppliesLikeAILists() async {
        // Prepare
        await self.filterListManager.refreshFilterLists()
        let allowSender = FilterExportRecord(text: "MyBank", type: "allow", folder: nil, target: "sender", matching: "exact", caseSensitivity: "insensitive")
        self.listsByURL[self.userURL] = self.payload(name: "Mine", filters: [self.denyRecord("loan"), allowSender])

        // Act
        await self.subscribe(self.userURL)

        // Verify
        let blocked = self.evaluate(body: "fast loan")
        XCTAssertEqual(blocked.action, .junk)
        XCTAssertEqual(blocked.match, .filterList("Mine"))
        XCTAssertEqual(self.evaluate(body: "loan approved", sender: "MyBank").action, .allow)
        XCTAssertEqual(self.filterListManager.communityLists.first?.isCurated, false)
        XCTAssertEqual(self.filterListManager.communityLists.first?.locale?.identifier, "he-IL")

        self.filterListManager.setCommunityListActive(self.communityList(self.userURL), value: false)
        XCTAssertEqual(self.evaluate(body: "fast loan").action, .allow)
    }

    @MainActor
    func test_subscribe_savesThePreviewedFile_withoutRefreshing() async {
        // Prepare
        await self.filterListManager.refreshFilterLists()
        let lastUpdated = self.filterListManager.filterListsLastUpdated
        self.listsByURL[self.userURL] = self.payload(filters: [self.denyRecord("loan")])
        self.filterListService.resetCounters()

        // Act
        await self.subscribe(self.userURL)

        // Verify
        XCTAssertEqual(self.filterListService.fetchFilterListCounter, 1, "only the preview downloads the file")
        XCTAssertEqual(self.filterListService.fetchFilterListCatalogCounter, 0)
        XCTAssertEqual(self.filterListManager.filterListsLastUpdated, lastUpdated, "the daily check still runs")
        XCTAssertEqual(self.persistenceManager.cachedFilterLists()?.cacheSection(for: self.userURL)?.etag, "mine.sfsfilters-1")
        XCTAssertEqual(self.evaluate(body: "fast loan").action, .junk)
    }

    @MainActor
    func test_subscribe_withoutCache_failsAndStaysOff() async {
        // Prepare
        self.listsByURL[self.userURL] = self.payload(filters: [self.denyRecord("loan")])
        let preview = await self.filterListManager.previewCommunityList(at: URL(string: self.userURL)!)
        guard case .success(let communityList) = preview else {
            XCTFail("preview failed")
            return
        }

        // Act
        let isSubscribed = await self.filterListManager.subscribeCommunityList(communityList)

        // Verify
        XCTAssertFalse(isSubscribed)
        XCTAssertTrue(self.filterListManager.communityLists.isEmpty)
        XCTAssertEqual(self.evaluate(body: "fast loan").action, .allow)
    }

    @MainActor
    func test_refresh_keepsSubscribedLists_dropsRemovedOnes() async {
        // Prepare
        await self.filterListManager.refreshFilterLists()
        self.listsByURL[self.userURL] = self.payload(filters: [self.denyRecord("loan")])
        await self.subscribe(self.userURL)

        // Act
        self.listsByURL[self.userURL] = self.payload(filters: [self.denyRecord("casino")])
        await self.filterListManager.refreshFilterLists()

        // Verify
        XCTAssertEqual(self.evaluate(body: "casino bonus").action, .junk, "a list outside the catalog still refreshes")

        self.filterListManager.removeCommunityList(self.communityList(self.userURL))
        await self.filterListManager.refreshFilterLists()
        XCTAssertTrue(self.filterListManager.communityLists.isEmpty)
        XCTAssertNil(self.persistenceManager.cachedFilterLists()?.lists.first(where: { $0.url == self.userURL }))
    }

    @MainActor
    func test_refresh_activeListUpdated_namesCommunityLists() async {
        // Prepare
        await self.filterListManager.refreshFilterLists()
        self.listsByURL[self.userURL] = self.payload(filters: [self.denyRecord("loan")])
        await self.subscribe(self.userURL)
        var updatedEntryType: FilterListCatalogEntryType?
        let observer = NotificationCenter.default.addObserver(forName: .filterListsUpdated, object: nil, queue: nil) { notification in
            updatedEntryType = notification.object as? FilterListCatalogEntryType
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        // Act
        self.listsByURL[self.userURL] = self.payload(filters: [self.denyRecord("casino")])
        await self.filterListManager.refreshFilterLists()

        // Verify
        XCTAssertEqual(updatedEntryType, .curatedCommunityList)
    }

    @MainActor
    func test_removeCuratedList_onlyTurnsItOff() async {
        // Prepare
        self.catalogEntries = [self.curatedEntry]
        self.listsByURL[self.curatedURL] = self.payload(filters: [self.denyRecord("loan")])
        await self.filterListManager.refreshFilterLists()
        self.filterListManager.setCommunityListActive(self.communityList(self.curatedURL), value: true)

        // Act
        self.filterListManager.removeCommunityList(self.communityList(self.curatedURL))

        // Verify
        XCTAssertEqual(self.filterListManager.communityLists.map(\.isActive), [false])
    }

    @MainActor
    func test_curatedListLeavesCatalog_removedEvenWhenOn() async {
        // Prepare
        self.catalogEntries = [self.curatedEntry]
        self.listsByURL[self.curatedURL] = self.payload(filters: [self.denyRecord("loan")])
        await self.filterListManager.refreshFilterLists()
        self.filterListManager.setCommunityListActive(self.communityList(self.curatedURL), value: true)

        // Act
        self.catalogEntries = []
        await self.filterListManager.refreshFilterLists()

        // Verify
        XCTAssertTrue(self.filterListManager.communityLists.isEmpty)
        XCTAssertTrue(self.persistenceManager.fetchCommunityListRecords().isEmpty)
        XCTAssertEqual(self.evaluate(body: "fast loan").action, .allow)
    }

    @MainActor
    func test_evaluation_communityAllowBeatsAIDeny() async {
        // Prepare
        self.catalogEntries = [FilterListCatalogEntry(id: "ai-en", name: "English", url: self.englishURL, language: "en")]
        self.listsByURL[self.englishURL] = self.payload(filters: [self.denyRecord("loan")])
        self.listsByURL[self.userURL] = self.payload(filters: [self.allowRecord("loan")])
        await self.filterListManager.refreshFilterLists()
        self.filterListManager.setFilterListActive(for: .english, value: true)
        XCTAssertEqual(self.evaluate(body: "fast loan").action, .junk)

        // Act
        await self.subscribe(self.userURL)

        // Verify
        XCTAssertEqual(self.evaluate(body: "fast loan").action, .allow, "allow lists run before deny lists, whoever owns them")
    }

    @MainActor
    func test_evaluation_aiListsMatchBeforeCommunityLists() async {
        // Prepare
        self.catalogEntries = [self.curatedEntry,
                               FilterListCatalogEntry(id: "ai-en", name: "English", url: self.englishURL, language: "en")]
        self.listsByURL[self.curatedURL] = self.payload(name: "Scam Guard", filters: [self.denyRecord("loan")])
        self.listsByURL[self.englishURL] = self.payload(filters: [self.denyRecord("loan")])
        await self.filterListManager.refreshFilterLists()

        // Act
        self.filterListManager.setCommunityListActive(self.communityList(self.curatedURL), value: true)
        self.filterListManager.setFilterListActive(for: .english, value: true)

        // Verify
        XCTAssertEqual(self.evaluate(body: "fast loan").match, .filterList(NLLanguage.english.localizedName!))
    }

    @MainActor
    func test_preview_refusesBadLinks() async {
        // Prepare
        await self.filterListManager.refreshFilterLists()
        self.listsByURL[self.userURL] = self.payload(filters: [])
        await self.subscribe(self.userURL)

        // Act
        let httpLink = await self.filterListManager.previewCommunityList(at: URL(string: "http://lists.example.com/a.sfsfilters")!)
        let listed = await self.filterListManager.previewCommunityList(at: URL(string: self.userURL)!)
        let notAList = await self.filterListManager.previewCommunityList(at: URL(string: "https://lists.example.com/page.html")!)
        self.listsByURL[self.curatedURL] = self.payload(name: nil, filters: [])
        let noName = await self.filterListManager.previewCommunityList(at: URL(string: self.curatedURL)!)
        self.listsByURL[self.curatedURL] = self.payload(description: "  ", filters: [])
        let blankDescription = await self.filterListManager.previewCommunityList(at: URL(string: self.curatedURL)!)
        self.listsByURL[self.curatedURL] = self.payload(author: nil, filters: [])
        let noAuthor = await self.filterListManager.previewCommunityList(at: URL(string: self.curatedURL)!)
        self.listsByURL[self.curatedURL] = self.payload(homepage: "http://example.com", filters: [])
        let httpHomepage = await self.filterListManager.previewCommunityList(at: URL(string: self.curatedURL)!)
        self.listsByURL[self.curatedURL] = self.payload(locale: nil, filters: [])
        let noLocale = await self.filterListManager.previewCommunityList(at: URL(string: self.curatedURL)!)
        self.listsByURL[self.otherURL] = self.payload(name: "Fresh", filters: [])
        let valid = await self.filterListManager.previewCommunityList(at: URL(string: self.otherURL)!)
        self.networkSyncManager.networkStatusClosure = { .offline }
        let offline = await self.filterListManager.previewCommunityList(at: URL(string: "https://lists.example.com/b.sfsfilters")!)

        // Verify
        XCTAssertEqual(httpLink.failure, .invalidURL)
        XCTAssertEqual(listed.failure, .alreadySubscribed)
        XCTAssertEqual(notAList.failure, .notAList)
        XCTAssertEqual(noName.failure, .missingName)
        XCTAssertEqual(blankDescription.failure, .missingDescription)
        XCTAssertEqual(noAuthor.failure, .missingAuthor)
        XCTAssertEqual(httpHomepage.failure, .invalidHomepage)
        XCTAssertEqual(noLocale.failure, .invalidLocale)
        let previewed = try? valid.get()
        XCTAssertEqual(previewed?.name, "Fresh")
        XCTAssertEqual(previewed?.author, "Jane Doe")
        XCTAssertEqual(previewed?.locale?.identifier, "he-IL")
        XCTAssertEqual(previewed?.isActive, false)
        XCTAssertEqual(previewed?.isCurated, false)
        XCTAssertEqual(offline.failure, .offline)
    }

    @MainActor
    func test_curatedEntry_bareFile_usesTheCatalog() async {
        // Prepare
        self.catalogEntries = [self.curatedEntry]
        self.listsByURL[self.curatedURL] = self.payload(name: nil, description: nil, author: nil, homepage: nil, locale: nil, filters: [self.denyRecord("loan")])

        // Act
        await self.filterListManager.refreshFilterLists()
        self.filterListManager.setCommunityListActive(self.communityList(self.curatedURL), value: true)

        // Verify
        let communityList = self.filterListManager.communityLists.first
        XCTAssertEqual(communityList?.name, "Scam Guard")
        XCTAssertEqual(communityList?.author, "Scam Guard Team")
        XCTAssertEqual(communityList?.locale?.identifier, "en-US")
        XCTAssertEqual(self.evaluate(body: "fast loan").match, .filterList("Scam Guard"))
    }

    @MainActor
    func test_curatedEntry_overridesTheFile() async {
        // Prepare
        self.catalogEntries = [FilterListCatalogEntry(id: "community-scam",
                                                      name: "Our Title",
                                                      url: self.curatedURL,
                                                      language: nil,
                                                      type: FilterListCatalogEntryType.curatedCommunityList.rawValue,
                                                      locale: "en-US",
                                                      description: "Our subtitle",
                                                      author: "Our Team",
                                                      homepage: "https://ours.example.com")]
        self.listsByURL[self.curatedURL] = self.payload(name: "Their Title", author: "Their Author", filters: [self.denyRecord("loan")])

        // Act
        await self.filterListManager.refreshFilterLists()
        self.filterListManager.setCommunityListActive(self.communityList(self.curatedURL), value: true)

        // Verify
        let communityList = self.filterListManager.communityLists.first
        XCTAssertEqual(communityList?.name, "Our Title")
        XCTAssertEqual(communityList?.description, "Our subtitle")
        XCTAssertEqual(communityList?.author, "Our Team")
        XCTAssertEqual(communityList?.homepage, URL(string: "https://ours.example.com"))
        XCTAssertEqual(self.evaluate(body: "fast loan").match, .filterList("Our Title"))
    }

    @MainActor
    func test_catalogEntry_ignoredWhenItsTypeIsUnknownOrIncomplete() async {
        // Prepare
        let curatedType = FilterListCatalogEntryType.curatedCommunityList.rawValue
        self.catalogEntries = [FilterListCatalogEntry(id: "future", name: "Future", url: self.userURL, language: "en", type: "something-new"),
                               FilterListCatalogEntry(id: "ai-none", name: "None", url: self.englishURL, language: nil),
                               FilterListCatalogEntry(id: "no-locale", name: "No Locale", url: self.curatedURL, language: nil, type: curatedType),
                               FilterListCatalogEntry(id: "bad-locale", name: "Bad Locale", url: self.curatedURL, language: nil, type: curatedType, locale: "zz-99")]
        self.listsByURL[self.userURL] = self.payload(filters: [])
        self.listsByURL[self.englishURL] = self.payload(filters: [])
        self.listsByURL[self.curatedURL] = self.payload(filters: [])

        // Act
        await self.filterListManager.refreshFilterLists()

        // Verify
        XCTAssertTrue(self.filterListManager.communityLists.isEmpty)
        XCTAssertTrue(self.filterListManager.filterListLanguages.isEmpty)
    }

    func test_catalogEntryType_untypedWithLanguageIsAIFiltering() {
        let untyped = FilterListCatalogEntry(id: "ai-he", name: "Hebrew", url: "he.sfsfilters", language: "he")
        let typed = FilterListCatalogEntry(id: "ai-he", name: "Hebrew", url: "he.sfsfilters", language: "he", type: "ai-filtering-language")

        XCTAssertEqual(untyped.entryType, .aiFilteringLanguage)
        XCTAssertEqual(typed.entryType, .aiFilteringLanguage)
        XCTAssertEqual(self.curatedEntry.entryType, .curatedCommunityList)
    }

    func test_ensuredRecord_mergesDuplicates() {
        // Prepare
        let first = CommunityList(context: self.persistenceManager.context)
        first.url = self.userURL
        let second = CommunityList(context: self.persistenceManager.context)
        second.url = self.userURL
        second.isActive = true

        // Act
        let ensured = self.persistenceManager.ensuredCommunityListRecord(for: self.userURL)
        _ = self.persistenceManager.commitContext()

        // Verify
        XCTAssertTrue(ensured.isActive)
        XCTAssertEqual(self.persistenceManager.fetchCommunityListRecords().count, 1)
    }

    func test_displayName_fallsBackToFileName() {
        XCTAssertEqual(FilterExportPayload.displayName(name: nil, url: "https://example.com/lists/simply.sfsfilters"), "simply")
        XCTAssertEqual(FilterExportPayload.displayName(name: "", url: "https://example.com/lists/simply.sfsfilters"), "simply")
        XCTAssertEqual(FilterExportPayload.displayName(name: "Named", url: self.userURL), "Named")
    }

    func test_homepage_acceptsOnlyHTTPSLinks() {
        XCTAssertEqual(CommunityListItem.homepageURL(from: "https://example.com"), URL(string: "https://example.com"))
        XCTAssertNil(CommunityListItem.homepageURL(from: "http://example.com"))
        XCTAssertNil(CommunityListItem.homepageURL(from: "javascript:alert(1)"))
        XCTAssertNil(CommunityListItem.homepageURL(from: "mailto:a@example.com"))
        XCTAssertNil(CommunityListItem.homepageURL(from: nil))
    }

    func test_listLocale_acceptsOnlyISOCodes() {
        XCTAssertEqual(Locale.listLocale(from: "en-US")?.identifier, "en-US")
        XCTAssertEqual(Locale.listLocale(from: "he")?.identifier, "he")
        XCTAssertNil(Locale.listLocale(from: "zz-99"))
        XCTAssertNil(Locale.listLocale(from: "english"))
        XCTAssertNil(Locale.listLocale(from: ""))
        XCTAssertNil(Locale.listLocale(from: nil))
    }


    //MARK: Private Variables and Helpers
    private var persistenceManager: PersistenceManager!
    private var filterListService: mock_FilterListService!
    private var networkSyncManager: mock_NetworkSyncManager!
    private var filterListManager: FilterListManager!
    private var messageEvaluationManager: MessageEvaluationManager!
    private var catalogEntries: [FilterListCatalogEntry] = []
    private var listsByURL: [String: FilterExportPayload] = [:]

    private var curatedEntry: FilterListCatalogEntry {
        return FilterListCatalogEntry(id: "community-scam",
                                      name: "Scam Guard",
                                      url: self.curatedURL,
                                      language: nil,
                                      type: FilterListCatalogEntryType.curatedCommunityList.rawValue,
                                      locale: "en-US",
                                      description: "Blocks scams",
                                      author: "Scam Guard Team",
                                      homepage: "https://example.com")
    }

    private let curatedURL = "https://github.com/example/rules/releases/latest/download/simply.sfsfilters"
    private let englishURL = "https://lists.example.com/en.sfsfilters"
    private let userURL = "https://lists.example.com/mine.sfsfilters"
    private let otherURL = "https://lists.example.com/other.sfsfilters"

    private func payload(name: String? = "Test List",
                         description: String? = "Blocks scams",
                         author: String? = "Jane Doe",
                         homepage: String? = "https://example.com",
                         locale: String? = "he-IL",
                         filters: [FilterExportRecord]) -> FilterExportPayload {
        return FilterExportPayload(format: FilterExportPayload.formatIdentifier,
                                   version: FilterExportPayload.currentVersion,
                                   exportedAt: Date(timeIntervalSince1970: 0),
                                   appVersion: "4.0.0",
                                   name: name,
                                   description: description,
                                   author: author,
                                   homepage: homepage,
                                   locale: locale,
                                   filters: filters,
                                   forceClearBeforeImport: nil)
    }

    @MainActor
    private func subscribe(_ url: String) async {
        let preview = await self.filterListManager.previewCommunityList(at: URL(string: url)!)
        guard case .success(let communityList) = preview else {
            XCTFail("preview failed for \(url)")
            return
        }
        let isSubscribed = await self.filterListManager.subscribeCommunityList(communityList)
        XCTAssertTrue(isSubscribed, "subscribing failed for \(url)")
    }

    private func communityList(_ url: String) -> CommunityListItem {
        guard let communityList = self.filterListManager.communityLists.first(where: { $0.url == url }) else {
            XCTFail("no community list for \(url)")
            return CommunityListItem(url: url, catalogEntry: nil, cacheSection: nil, isActive: false)
        }
        return communityList
    }

    private func denyRecord(_ text: String) -> FilterExportRecord {
        return FilterExportRecord(text: text, type: "deny", folder: "junk", target: "body", matching: "contains", caseSensitivity: "insensitive")
    }

    private func allowRecord(_ text: String) -> FilterExportRecord {
        return FilterExportRecord(text: text, type: "allow", folder: nil, target: "body", matching: "contains", caseSensitivity: "insensitive")
    }

    private func evaluate(body: String, sender: String = "1234567") -> MessageEvaluationResult {
        return self.messageEvaluationManager.evaluateMessage(body: body, sender: sender)
    }
}

private extension Result {
    var failure: Failure? {
        guard case .failure(let error) = self else { return nil }
        return error
    }
}
