//
//  AddFilterIntent.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 19/11/2026.
//

import AppIntents

struct AddFilterIntent: AppIntent {
    static let title: LocalizedStringResource = "siri_addFilter_title"
    static let description = IntentDescription("siri_addFilter_description")

    @Parameter(title: "siri_addFilter_list",
               requestValueDialog: IntentDialog("siri_addFilter_listPrompt"))
    var list: FilterListChoice

    @Parameter(title: "siri_addFilter_text",
               requestValueDialog: IntentDialog("siri_addFilter_textPrompt"))
    var text: String

    init() {}

    init(list: FilterListChoice) {
        self.list = list
    }

    static var parameterSummary: some ParameterSummary {
        Switch(\.$list) {
            Case(.block) {
                Summary("siri_addFilter_summary_block \(\.$text)")
            }
            Case(.allow) {
                Summary("siri_addFilter_summary_allow \(\.$text)")
            }
            DefaultCase {
                Summary("siri_addFilter_summary_unset \(\.$text) \(\.$list)")
            }
        }
    }


    //MARK: - Public API -
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let persistenceManager = SimplyFilterSMSShortcuts.appManager.persistenceManager
        let filterType = self.list.filterType
        let filterText = self.text.dictatedFilterText
        let message: String

        if filterText.count < kMinimumFilterLength {
            Log.debug("siri add filter, type: \(filterType), spoken: \(self.text) → too short")
            message = "siri_addFilter_empty"~
        }
        else if persistenceManager.isDuplicateFilter(text: filterText,
                                                     filterTarget: Self.filterTarget,
                                                     filterMatching: Self.filterMatching,
                                                     filterCase: Self.filterCase) {
            Log.debug("siri add filter, type: \(filterType), spoken: \(self.text), text: \(filterText) → duplicate")
            message = String(format: "siri_addFilter_duplicate"~, filterText)
        }
        else if persistenceManager.addFilter(text: filterText,
                                             type: filterType,
                                             denyFolder: Self.denyFolder,
                                             filterTarget: Self.filterTarget,
                                             filterMatching: Self.filterMatching,
                                             filterCase: Self.filterCase) != nil {
            Log.debug("siri add filter, type: \(filterType), spoken: \(self.text), text: \(filterText) → added")
            message = String(format: self.list.addedFormat, filterText)
        }
        else {
            Log.debug("siri add filter, type: \(filterType), spoken: \(self.text), text: \(filterText) → not saved")
            message = "siri_addFilter_failed"~
        }

        return .result(dialog: IntentDialog(stringLiteral: message))
    }


    //MARK: - Private -
    private static let denyFolder = MessageFolder.junk
    private static let filterTarget = FilterTarget.all
    private static let filterMatching = FilterMatching.contains
    private static let filterCase = FilterCase.caseInsensitive
}

enum FilterListChoice: String, AppEnum, CaseIterable {
    case block, allow

    static let typeDisplayRepresentation: TypeDisplayRepresentation = "siri_filterList_type"
    static let caseDisplayRepresentations: [FilterListChoice: DisplayRepresentation] = [
        .block: "filterList_denied",
        .allow: "filterList_allowed"
    ]

    init?(filterType: FilterType) {
        switch filterType {
        case .deny:
            self = .block
        case .allow:
            self = .allow
        case .denyLanguage:
            return nil
        }
    }

    var filterType: FilterType {
        switch self {
        case .block:
            return .deny
        case .allow:
            return .allow
        }
    }

    var addedFormat: String {
        switch self {
        case .block:
            return "siri_addFilter_added_block"~
        case .allow:
            return "siri_addFilter_added_allow"~
        }
    }
}
