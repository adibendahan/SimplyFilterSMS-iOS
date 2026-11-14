//
//  FilterListCatalogResponse.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 28/10/2026.
//

import Foundation
import NaturalLanguage


struct FilterListCatalogResponse: Codable, Equatable {
    static let formatIdentifier = "simply-filter-sms-catalog"
    static let currentVersion = 2

    let format: String
    let version: Int
    let lists: [FilterListCatalogEntry]
}

struct FilterListCatalogEntry: Codable, Equatable {
    let id: String
    let name: String
    let url: String
    let language: String?
    var type: String? = nil
    var locale: String? = nil
    var description: String? = nil
    var author: String? = nil
    var homepage: String? = nil
}

enum FilterListCatalogEntryType: String {
    case aiFilteringLanguage = "ai-filtering-language"
    case curatedCommunityList = "curated-community-list"
}

extension FilterListCatalogResponse {
    init?(data: Data) {
        let response: Self
        do {
            response = try JSONDecoder().decode(Self.self, from: data)
        } catch {
            Log.error("catalog doesn't decode, bytes: \(data.count)", error: error)
            return nil
        }
        guard response.format == Self.formatIdentifier, response.version >= 1 else {
            Log.error("catalog has the wrong format, format: \(response.format), version: \(response.version)")
            return nil
        }
        guard response.version <= Self.currentVersion else {
            Log.error("catalog version not supported, version: \(response.version), supported: \(Self.currentVersion)")
            return nil
        }

        self = response
    }

    var curatedCommunityListURLs: [String] {
        let curatedURLs = self.curatedCommunityListEntries.compactMap(\.resolvedURL?.absoluteString)
        return curatedURLs.uniqued()
    }

    func curatedEntry(for url: String) -> FilterListCatalogEntry? {
        return self.curatedCommunityListEntries.first { $0.resolvedURL?.absoluteString == url }
    }

    func aiFilteringEntriesByURL(activeLanguages: Set<String>) -> [String: FilterListCatalogEntry] {
        var entriesByURL: [String: FilterListCatalogEntry] = [:]
        for entry in self.lists {
            guard entry.entryType == .aiFilteringLanguage,
                  let language = entry.language,
                  activeLanguages.contains(language),
                  let listURL = entry.resolvedURL else { continue }
            entriesByURL[listURL.absoluteString] = entry
        }
        return entriesByURL
    }

    private var curatedCommunityListEntries: [FilterListCatalogEntry] {
        return self.lists.filter { $0.entryType == .curatedCommunityList }
    }
}

extension FilterListCatalogEntry {
    var entryType: FilterListCatalogEntryType? {
        let declaredType = self.declaredType
        switch declaredType {
        case .aiFilteringLanguage:
            return self.language == nil ? nil : .aiFilteringLanguage
        case .curatedCommunityList:
            return Locale.listLocale(from: self.locale) == nil ? nil : .curatedCommunityList
        case nil:
            return nil
        }
    }

    private var declaredType: FilterListCatalogEntryType? {
        guard let type = self.type else { return .aiFilteringLanguage }
        return FilterListCatalogEntryType(rawValue: type)
    }

    var resolvedURL: URL? {
        return URL(string: self.url, relativeTo: .filterListCatalogURL)?.absoluteURL
    }

    var displayName: String {
        guard let language = self.language else { return self.name }
        let nlLanguage = NLLanguage(rawValue: language)
        return nlLanguage.localizedName ?? self.name
    }
}
