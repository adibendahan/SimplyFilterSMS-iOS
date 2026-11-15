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

    let home: HomeScreen
    let allowList: FilterListScreen
    let denyList: FilterListScreen
    let aiFiltering: AIFilteringScreen
    let communityLists: CommunityListsScreen
    let filterTransfer: FilterTransferScreen
    private let filterTester: FilterTesterScreen

    init(remoteLists: RemoteLists) {
        var arguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if remoteLists == .testCatalog {
            arguments.append("-UITestData")
        }
        let app = XCUIApplication.launchSimplyFilter(arguments: arguments)

        self.home = HomeScreen(app: app)
        self.allowList = FilterListScreen(app: app, kind: .allow)
        self.denyList = FilterListScreen(app: app, kind: .deny)
        self.aiFiltering = AIFilteringScreen(app: app)
        self.communityLists = CommunityListsScreen(app: app)
        self.filterTransfer = FilterTransferScreen(app: app)
        self.filterTester = FilterTesterScreen(app: app)
    }

    func expect(_ message: Message, toBe verdict: Verdict, file: StaticString = #filePath, line: UInt = #line) {
        self.filterTester.expect(message, toBe: verdict, file: file, line: line)
    }
}
