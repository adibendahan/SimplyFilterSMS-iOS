//
//  SimplyFilterApp.swift
//  Scenario Tests
//
//  Created by Adi Ben-Dahan on 15/11/2026.
//

import XCTest

@MainActor
final class SimplyFilterApp {
    enum RemoteLists {
        case off
        case testCatalog
    }

    enum StartingData {
        case empty
        case debug
    }

    let home: HomeScreen
    let allowList: FilterListScreen
    let denyList: FilterListScreen
    let aiFiltering: AIFilteringScreen
    let communityLists: CommunityListsScreen
    let filterTransfer: FilterTransferScreen
    let stayReachable: StayReachableScreen
    let search: SearchScreen
    private let filterTester: FilterTesterScreen

    init(remoteLists: RemoteLists, phoneLanguages: [Language], startingData: StartingData) {
        let languageCodes = phoneLanguages.map(\.rawValue).joined(separator: ", ")
        var arguments = ["-AppleLanguages", "(\(languageCodes))", "-AppleLocale", "en_US"]
        if remoteLists == .testCatalog {
            arguments.append("-UITestData")
        }
        if startingData == .debug {
            arguments.append("-DebugData")
        }
        let app = XCUIApplication.launchSimplyFilter(arguments: arguments)

        self.home = HomeScreen(app: app)
        self.allowList = FilterListScreen(app: app, kind: .allow)
        self.denyList = FilterListScreen(app: app, kind: .deny)
        self.aiFiltering = AIFilteringScreen(app: app)
        self.communityLists = CommunityListsScreen(app: app)
        self.filterTransfer = FilterTransferScreen(app: app)
        self.stayReachable = StayReachableScreen(app: app, phoneLanguages: phoneLanguages)
        self.search = SearchScreen(app: app)
        self.filterTester = FilterTesterScreen(app: app)
    }

    func expect(_ message: Message, toBe verdict: Verdict, file: StaticString = #filePath, line: UInt = #line) {
        self.testYourFilters { tester in
            tester.expect(message, toBe: verdict, file: file, line: line)
        }
    }

    func testYourFilters(_ checks: (FilterTesterScreen) -> Void) {
        self.filterTester.open()
        checks(self.filterTester)
        self.filterTester.close()
    }
}
