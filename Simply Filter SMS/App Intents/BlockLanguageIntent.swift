//
//  BlockLanguageIntent.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/11/2026.
//

import AppIntents
import NaturalLanguage

struct BlockLanguageIntent: AppIntent {
    static let title: LocalizedStringResource = "siri_blockLanguage_title"
    static let description = IntentDescription("siri_blockLanguage_description")

    @Parameter(title: "siri_blockLanguage_language",
               requestValueDialog: IntentDialog("siri_blockLanguage_languagePrompt"))
    var language: LanguageEntity

    static var parameterSummary: some ParameterSummary {
        Summary("siri_blockLanguage_summary \(\.$language)")
    }


    //MARK: - Public API -
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let persistenceManager = SimplyFilterSMSShortcuts.appManager.persistenceManager
        let language = self.language.language
        let message: String

        if persistenceManager.isDuplicateFilter(language: language) {
            Log.debug("siri block language, language: \(language.rawValue) → already blocked")
            message = String(format: "siri_blockLanguage_duplicate"~, self.language.name)
        }
        else if persistenceManager.addFilter(text: language.filterText,
                                             type: .denyLanguage,
                                             denyFolder: .junk,
                                             filterTarget: .body,
                                             filterMatching: .contains,
                                             filterCase: .caseInsensitive) != nil {
            Log.debug("siri block language, language: \(language.rawValue) → blocked")
            message = String(format: "siri_blockLanguage_blocked"~, self.language.name)
        }
        else {
            Log.debug("siri block language, language: \(language.rawValue) → not saved")
            message = "siri_addFilter_failed"~
        }

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

struct LanguageEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "siri_language_type"
    static let defaultQuery = LanguageEntityQuery()

    let id: String

    var language: NLLanguage {
        return NLLanguage(rawValue: self.id)
    }

    var name: String {
        return self.language.localizedName ?? self.id
    }

    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "\(self.name)")
    }
}

struct LanguageEntityQuery: EnumerableEntityQuery {

    //MARK: - Public API (EnumerableEntityQuery) -
    func allEntities() async throws -> [LanguageEntity] {
        let languages = NLLanguage.allSupportedCases.sorted(by: NLLanguage.displayOrder)
        return languages.map({ LanguageEntity(id: $0.rawValue) })
    }

    func entities(for identifiers: [String]) async throws -> [LanguageEntity] {
        let supportedIdentifiers = NLLanguage.allSupportedCases.map(\.rawValue)
        let identifiers = identifiers.filter({ supportedIdentifiers.contains($0) })
        return identifiers.map({ LanguageEntity(id: $0) })
    }
}
