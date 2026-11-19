//
//  RemoveFilterIntent.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/11/2026.
//

import AppIntents
import NaturalLanguage

struct RemoveFilterIntent: AppIntent {
    static let title: LocalizedStringResource = "siri_removeFilter_title"
    static let description = IntentDescription("siri_removeFilter_description")

    @Parameter(title: "siri_removeFilter_filter",
               requestValueDialog: IntentDialog("siri_removeFilter_filterPrompt"))
    var filter: FilterEntity

    static var parameterSummary: some ParameterSummary {
        Summary("siri_removeFilter_summary \(\.$filter)")
    }


    //MARK: - Public API -
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let persistenceManager = SimplyFilterSMSShortcuts.appManager.persistenceManager
        let confirmation = String(format: "siri_removeFilter_confirm"~, self.filter.name, self.filter.listName)
        let isConfirmed = try await self.$filter.requestConfirmation(for: self.filter,
                                                                     dialog: IntentDialog(stringLiteral: confirmation))

        let records = persistenceManager.fetchFilterRecords()
        let message: String
        if !isConfirmed {
            Log.debug("siri remove filter, uuid: \(self.filter.id) → not confirmed")
            message = "siri_removeFilter_cancelled"~
        }
        else if let record = records.first(where: { $0.uuid == self.filter.id }) {
            Log.debug("siri remove filter, type: \(record.filterType), text: \(record.text) → removed")
            persistenceManager.deleteFilters([record])
            message = String(format: "siri_removeFilter_removed"~, self.filter.name)
        }
        else {
            Log.debug("siri remove filter, uuid: \(self.filter.id) → not found")
            message = "siri_removeFilter_notFound"~
        }

        return .result(dialog: IntentDialog(stringLiteral: message))
    }
}

struct FilterEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "siri_filter_type"
    static let defaultQuery = FilterEntityQuery()

    let id: UUID
    let name: String
    let listName: String

    var displayRepresentation: DisplayRepresentation {
        return DisplayRepresentation(title: "\(self.name)", subtitle: "\(self.listName)")
    }

    init?(filter: Filter) {
        guard let uuid = filter.uuid, let text = filter.text else { return nil }
        let name: String
        if filter.filterType == .denyLanguage {
            name = NLLanguage(filterText: text).localizedName ?? text
        }
        else {
            name = text
        }
        self.id = uuid
        self.name = name
        self.listName = filter.filterType.name
    }
}

struct FilterEntityQuery: EntityStringQuery {

    //MARK: - Public API (EntityStringQuery) -
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [FilterEntity] {
        let entities = Self.allEntities()
        return entities.filter({ identifiers.contains($0.id) })
    }

    @MainActor
    func entities(matching string: String) async throws -> [FilterEntity] {
        let spokenText = string.dictatedFilterText
        let entities = Self.allEntities()
        let matches = entities.filter({ $0.name.localizedCaseInsensitiveContains(spokenText) })
        Log.debug("siri filter search, spoken: \(string), matches: \(matches.count)")
        return matches
    }

    @MainActor
    func suggestedEntities() async throws -> [FilterEntity] {
        return Self.allEntities()
    }


    //MARK: - Private -
    @MainActor
    private static func allEntities() -> [FilterEntity] {
        let records = SimplyFilterSMSShortcuts.appManager.persistenceManager.fetchFilterRecords()
        return records.compactMap(FilterEntity.init(filter:))
    }
}
