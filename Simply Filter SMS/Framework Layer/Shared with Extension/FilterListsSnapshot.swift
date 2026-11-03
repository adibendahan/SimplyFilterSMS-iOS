//
//  FilterListsSnapshot.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 29/10/2026.
//

import Foundation


struct FilterListsSnapshot: Codable, Equatable {
    let catalogETag: String?
    let catalog: FilterListCatalogResponse
    let lists: [FilterListsCacheSection]
}

struct FilterListsCacheSection: Codable, Equatable {
    let url: String
    let etag: String?
    let payload: FilterExportPayload
}

struct ActiveFilterLists {
    let lists: [ActiveFilterList]
}

struct ActiveFilterList {
    let name: String
    let records: [FilterExportRecord]
}

extension FilterListsSnapshot {
    init?(encoded: String) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let data = encoded.data(using: .utf8),
              let cache = try? decoder.decode(Self.self, from: data) else { return nil }

        self = cache
    }

    var encoded: String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

extension FilterListsSnapshot {
    init?(legacyEncoded: String) {
        guard let data = Data(base64Encoded: legacyEncoded, options: .ignoreUnknownCharacters),
              let legacy = try? JSONDecoder().decode(LegacyFilterLists.self, from: data) else { return nil }

        var entries: [FilterListCatalogEntry] = []
        var sections: [FilterListsCacheSection] = []
        for language in legacy.filterLists.keys.sorted() {
            guard let languageLists = legacy.filterLists[language] else { continue }
            let entry = FilterListCatalogEntry(id: "legacy-\(language)",
                                               name: language,
                                               url: "legacy/\(language)",
                                               language: language)
            guard let url = entry.resolvedURL else { continue }
            let payload = FilterExportPayload(format: FilterExportPayload.formatIdentifier,
                                              version: FilterExportPayload.currentVersion,
                                              exportedAt: Date(timeIntervalSince1970: 0),
                                              appVersion: "3.2",
                                              name: language,
                                              revision: nil,
                                              filters: languageLists.records,
                                              forceClearBeforeImport: nil)
            entries.append(entry)
            sections.append(FilterListsCacheSection(url: url.absoluteString, etag: nil, payload: payload))
        }

        let catalog = FilterListCatalogResponse(format: FilterListCatalogResponse.formatIdentifier,
                                                version: FilterListCatalogResponse.currentVersion,
                                                lists: entries)
        self.init(catalogETag: nil, catalog: catalog, lists: sections)
    }
}

extension FilterListCatalogResponse {
    init?(encodedCache: String) {
        guard let data = encodedCache.data(using: .utf8),
              let cachedCatalog = try? JSONDecoder().decode(CachedCatalog.self, from: data) else { return nil }

        self = cachedCatalog.catalog
    }
}

extension ActiveFilterLists {
    init?(encoded: String, activeLanguages: Set<String>) {
        guard let catalog = FilterListCatalogResponse(encodedCache: encoded),
              let data = encoded.data(using: .utf8) else { return nil }

        var namesByURL: [String: String] = [:]
        for entry in catalog.lists {
            guard let language = entry.language, activeLanguages.contains(language) else { continue }
            guard let url = entry.resolvedURL else { continue }
            namesByURL[url.absoluteString] = entry.displayName
        }

        let decoder = JSONDecoder()
        decoder.userInfo[.activeURLs] = Set(namesByURL.keys)
        guard let cachedLists = try? decoder.decode(CachedLists.self, from: data) else { return nil }

        var lists: [ActiveFilterList] = []
        for cachedList in cachedLists.lists {
            guard let name = namesByURL[cachedList.url], let records = cachedList.records else { continue }
            lists.append(ActiveFilterList(name: name, records: records))
        }

        self.lists = lists
    }
}

//MARK: - Private -
private struct CachedCatalog: Decodable {
    let catalog: FilterListCatalogResponse
}

private struct CachedLists: Decodable {
    let lists: [CachedList]
}

private struct CachedList: Decodable {
    let url: String
    let records: [FilterExportRecord]?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let activeURLs = decoder.userInfo[.activeURLs] as? Set<String> ?? []
        self.url = try container.decode(String.self, forKey: .url)

        guard activeURLs.contains(self.url) else {
            self.records = nil
            return
        }
        let payload = try container.decode(Payload.self, forKey: .payload)
        self.records = payload.filters
    }

    private struct Payload: Decodable {
        let filters: [FilterExportRecord]
    }

    private enum CodingKeys: String, CodingKey {
        case url, payload
    }
}

private struct LegacyFilterLists: Decodable {
    let filterLists: [String: LegacyLanguageLists]

    private enum CodingKeys: String, CodingKey {
        case filterLists = "filter_lists"
    }
}

private struct LegacyLanguageLists: Decodable {
    let allowSender: [String]
    let allowBody: [String]
    let denySender: [String]
    let denyBody: [String]

    var records: [FilterExportRecord] {
        let allowSenders = self.allowSender.map { Self.senderRecord($0, type: "allow", folder: nil) }
        let allowBodies = self.allowBody.map { Self.bodyRecord($0, type: "allow", folder: nil) }
        let denySenders = self.denySender.map { Self.senderRecord($0, type: "deny", folder: "junk") }
        let denyBodies = self.denyBody.map { Self.bodyRecord($0, type: "deny", folder: "junk") }
        return allowSenders + allowBodies + denySenders + denyBodies
    }

    private static func senderRecord(_ sender: String, type: String, folder: String?) -> FilterExportRecord {
        let escapedSender = NSRegularExpression.escapedPattern(for: sender)
        return FilterExportRecord(text: "(?i)^\(escapedSender)$",
                                  type: type,
                                  folder: folder,
                                  target: "sender",
                                  matching: "regex",
                                  caseSensitivity: nil)
    }

    private static func bodyRecord(_ body: String, type: String, folder: String?) -> FilterExportRecord {
        return FilterExportRecord(text: body,
                                  type: type,
                                  folder: folder,
                                  target: "body",
                                  matching: "contains",
                                  caseSensitivity: "insensitive")
    }

    private enum CodingKeys: String, CodingKey {
        case allowSender = "allow_sender"
        case allowBody = "allow_body"
        case denySender = "deny_sender"
        case denyBody = "deny_body"
    }
}

private extension CodingUserInfoKey {
    static let activeURLs = CodingUserInfoKey(rawValue: "activeURLs")!
}
