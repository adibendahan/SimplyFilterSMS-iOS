//
//  SimplyFilterSMSShortcuts.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 19/11/2026.
//

import AppIntents

struct SimplyFilterSMSShortcuts: AppShortcutsProvider {
    static var appManager: AppManagerProtocol = AppManager.shared

    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: AddFilterIntent(),
                    phrases: [
                        "Add to my \(\.$list) in \(.applicationName)",
                        "Add a filter to my \(\.$list) in \(.applicationName)",
                        "Add a filter in \(.applicationName)"
                    ],
                    shortTitle: "siri_addFilter_shortTitle",
                    systemImageName: "plus.message")
        AppShortcut(intent: RemoveFilterIntent(),
                    phrases: [
                        "Remove a filter in \(.applicationName)",
                        "Delete a filter in \(.applicationName)"
                    ],
                    shortTitle: "siri_removeFilter_shortTitle",
                    systemImageName: "trash")
        AppShortcut(intent: CheckMessageIntent(),
                    phrases: [
                        "Check a message in \(.applicationName)",
                        "Test a message in \(.applicationName)"
                    ],
                    shortTitle: "siri_checkMessage_shortTitle",
                    systemImageName: "checkmark.message")
        AppShortcut(intent: BlockLanguageIntent(),
                    phrases: [
                        "Block \(\.$language) texts in \(.applicationName)",
                        "Block a language in \(.applicationName)"
                    ],
                    shortTitle: "siri_blockLanguage_shortTitle",
                    systemImageName: "globe")
        AppShortcut(intent: UpdateFilterListsIntent(),
                    phrases: [
                        "Update my filter lists in \(.applicationName)",
                        "Refresh my filter lists in \(.applicationName)"
                    ],
                    shortTitle: "siri_updateLists_shortTitle",
                    systemImageName: "arrow.clockwise")
    }
}
