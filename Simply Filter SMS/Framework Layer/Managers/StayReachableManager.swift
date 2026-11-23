//
//  StayReachableManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 24/11/2026.
//

import Foundation

class StayReachableManager: StayReachableManagerProtocol {

    //MARK: - Initialization -
    init(persistenceManager: PersistenceManagerProtocol,
         defaultsManager: DefaultsManagerProtocol) {
        self.persistenceManager = persistenceManager
        self.defaultsManager = defaultsManager
    }


    //MARK: - Public API (StayReachableManagerProtocol) -
    func rememberedSections(in filters: [Filter]) -> [StayReachableSection] {
        var sections: [StayReachableSection] = []
        for storedSection in self.defaultsManager.stayReachableFilterIDs {
            guard let identifier = storedSection[Self.languageKey] else { continue }
            var section = StayReachableSection(language: Locale.LanguageCode(identifier))
            for field in StayReachableField.allCases {
                guard let filterID = storedSection[field.rawValue],
                      let filter = filters.first(where: { $0.uuid?.uuidString == filterID }) else { continue }
                section[keyPath: field.keyPath] = filter.text ?? ""
                section.restoredFilters[field] = filter
            }
            guard !section.isBlank else { continue }
            sections.append(section)
        }
        Log.debug("remembered sections loaded, stored: \(self.defaultsManager.stayReachableFilterIDs.count), restored: \(sections.map(\.language.identifier))")
        return sections
    }

    func isAlreadyAllowed(_ text: String, excluding ownFilter: Filter?, in filters: [Filter]) -> Bool {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedText.count >= kMinimumFilterLength else { return false }
        let signature = Self.allowSignature(for: trimmedText)
        let otherFilters = filters.filter { $0 != ownFilter }
        return otherFilters.contains { signature.isDuplicate(of: $0.signature) }
    }

    func save(_ sections: [StayReachableSection]) {
        var clearedFilters: Set<Filter> = []
        for section in sections {
            for field in StayReachableField.allCases {
                let trimmedText = section.trimmedText(field)
                let restoredFilter = section.restoredFilters[field]
                if trimmedText.isEmpty, let restoredFilter {
                    clearedFilters.insert(restoredFilter)
                }
                guard trimmedText.count >= kMinimumFilterLength, !section.isUnchanged(field) else { continue }
                if let restoredFilter {
                    self.persistenceManager.updateFilter(restoredFilter, filterText: trimmedText)
                } else {
                    let signature = Self.allowSignature(for: trimmedText)
                    _ = self.persistenceManager.addFilter(text: signature.text,
                                                          type: .allow,
                                                          denyFolder: .junk,
                                                          filterTarget: signature.filterTarget,
                                                          filterMatching: signature.filterMatching,
                                                          filterCase: signature.filterCase)
                }
            }
        }
        if !clearedFilters.isEmpty {
            Log.debug("restored fields cleared, texts: \(clearedFilters.map { $0.text ?? "" }) → deleting their filters")
            self.persistenceManager.deleteFilters(clearedFilters)
        }
        self.rememberFilterIDs(for: sections)
    }


    //MARK: - Private -
    private let persistenceManager: PersistenceManagerProtocol
    private var defaultsManager: DefaultsManagerProtocol

    private static let languageKey = "language"

    private static func allowSignature(for text: String) -> FilterSignature {
        return FilterSignature(text: text,
                               filterTarget: .all,
                               filterMatching: .exact,
                               filterCase: .caseInsensitive)
    }

    private func rememberFilterIDs(for sections: [StayReachableSection]) {
        let allowFilters = self.persistenceManager.fetchFilterRecords(for: .allow)
        var storedSections: [[String: String]] = []
        for section in sections {
            var filterIDs: [String: String] = [:]
            for field in StayReachableField.allCases {
                let trimmedText = section.trimmedText(field)
                guard trimmedText.count >= kMinimumFilterLength else { continue }
                let signature = Self.allowSignature(for: trimmedText)
                let matchingFilter = allowFilters.first { signature.isDuplicate(of: $0.signature) }
                let filter = section.restoredFilters[field] ?? matchingFilter
                guard let filterID = filter?.uuid?.uuidString else { continue }
                filterIDs[field.rawValue] = filterID
            }
            guard !filterIDs.isEmpty else { continue }
            filterIDs[Self.languageKey] = section.language.identifier
            storedSections.append(filterIDs)
        }
        self.defaultsManager.stayReachableFilterIDs = storedSections
        Log.debug("filter IDs remembered, sections: \(storedSections.compactMap { $0[Self.languageKey] })")
    }
}
