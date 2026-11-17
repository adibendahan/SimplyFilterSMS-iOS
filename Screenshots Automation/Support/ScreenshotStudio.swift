//
//  ScreenshotStudio.swift
//  Screenshots Automation
//
//  Created by Adi Ben-Dahan on 16/11/2026.
//

import XCTest

@MainActor
final class ScreenshotStudio {
    let device: ShotDevice
    let aiFiltering: AIFilteringScreen
    let blockedTexts: FilterListScreen
    let allowedTexts: FilterListScreen
    let blockedLanguages: BlockedLanguagesScreen
    let filterTester: FilterTesterScreen
    let countries: CountriesScreen
    let communityLists: CommunityListsScreen

    init() {
        let app = XCUIApplication.launchSimplyFilter(arguments: ["-ScreenshotData"])
        self.device = ShotDevice(app: app)
        self.aiFiltering = AIFilteringScreen(app: app)
        self.blockedTexts = FilterListScreen(app: app, link: .denyFiltersLink)
        self.allowedTexts = FilterListScreen(app: app, link: .allowFiltersLink)
        self.blockedLanguages = BlockedLanguagesScreen(app: app)
        self.filterTester = FilterTesterScreen(app: app)
        self.countries = CountriesScreen(app: app)
        self.communityLists = CommunityListsScreen(app: app)
    }

    func fillDetailPane() {
        guard self.device.usesSplitLayout else { return }
        self.aiFiltering.show(activeLanguage: .current)
    }
}
