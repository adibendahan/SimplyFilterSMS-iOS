//
//  UpdateFilterListsIntent.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/11/2026.
//

import AppIntents

struct UpdateFilterListsIntent: AppIntent {
    static let title: LocalizedStringResource = "siri_updateLists_title"
    static let description = IntentDescription("siri_updateLists_description")


    //MARK: - Public API -
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let filterListManager = SimplyFilterSMSShortcuts.appManager.filterListManager
        let lastUpdatedBefore = filterListManager.filterListsLastUpdated
        await filterListManager.refreshFilterLists()
        let lastUpdatedAfter = filterListManager.filterListsLastUpdated
        let didUpdate = lastUpdatedAfter != nil && lastUpdatedAfter != lastUpdatedBefore
        Log.debug("siri update lists, lastUpdated: \(lastUpdatedBefore) → \(lastUpdatedAfter), updated: \(didUpdate)")

        let message: String
        if didUpdate {
            message = "siri_updateLists_updated"~
        }
        else {
            message = "siri_updateLists_failed"~
        }

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}
