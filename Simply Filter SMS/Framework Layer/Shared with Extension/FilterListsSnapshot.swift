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
        let jsonData = Data(encoded.utf8)
        do {
            self = try decoder.decode(Self.self, from: jsonData)
        } catch {
            Log.error("snapshot doesn't decode, bytes: \(jsonData.count)", error: error)
            return nil
        }
    }

    var encoded: String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        encoder.dateEncodingStrategy = .iso8601
        do {
            let jsonData = try encoder.encode(self)
            return String(decoding: jsonData, as: UTF8.self)
        } catch {
            Log.error("snapshot doesn't encode, lists: \(self.lists.count)", error: error)
            return nil
        }
    }
}

extension FilterListsSnapshot {
    init?(legacyEncoded: String) {
        guard let legacyJSON = Data(base64Encoded: legacyEncoded, options: .ignoreUnknownCharacters) else {
            Log.error("3.2 cache isn't base64, characters: \(legacyEncoded.count)")
            return nil
        }
        let legacyFilterLists: LegacyFilterLists
        do {
            legacyFilterLists = try JSONDecoder().decode(LegacyFilterLists.self, from: legacyJSON)
        } catch {
            Log.error("3.2 cache doesn't decode, bytes: \(legacyJSON.count)", error: error)
            return nil
        }

        var catalogEntries: [FilterListCatalogEntry] = []
        var cacheSections: [FilterListsCacheSection] = []
        for language in legacyFilterLists.filterLists.keys.sorted() {
            guard let languageLists = legacyFilterLists.filterLists[language] else { continue }
            let catalogEntry = FilterListCatalogEntry(id: "legacy-\(language)",
                                                      name: language,
                                                      url: "legacy/\(language)",
                                                      language: language)
            guard let listURL = catalogEntry.resolvedURL else { continue }
            let listPayload = FilterExportPayload(format: FilterExportPayload.formatIdentifier,
                                                  version: FilterExportPayload.currentVersion,
                                                  exportedAt: Date(timeIntervalSince1970: 0),
                                                  appVersion: "3.2",
                                                  name: language,
                                                  revision: nil,
                                                  description: nil,
                                                  homepage: nil,
                                                  locale: nil,
                                                  filters: languageLists.records,
                                                  forceClearBeforeImport: nil)
            catalogEntries.append(catalogEntry)
            cacheSections.append(FilterListsCacheSection(url: listURL.absoluteString, etag: nil, payload: listPayload))
        }

        let catalog = FilterListCatalogResponse(format: FilterListCatalogResponse.formatIdentifier,
                                                version: FilterListCatalogResponse.currentVersion,
                                                lists: catalogEntries)
        self.init(catalogETag: nil, catalog: catalog, lists: cacheSections)
    }
}

extension FilterListsSnapshot {
    func cacheSection(for url: String) -> FilterListsCacheSection? {
        return self.lists.first { $0.url == url }
    }
}

extension FilterExportPayload {
    static func displayName(name: String?, url: String) -> String {
        if let name, !name.isEmpty {
            return name
        }
        guard let listURL = URL(string: url), !listURL.lastPathComponent.isEmpty else { return url }
        return listURL.deletingPathExtension().lastPathComponent
    }
}

extension FilterListCatalogResponse {
    init?(encodedCache: String) {
        let jsonData = Data(encodedCache.utf8)
        do {
            self = try JSONDecoder().decode(CachedCatalog.self, from: jsonData).catalog
        } catch {
            Log.error("cached catalog doesn't decode, bytes: \(jsonData.count)", error: error)
            return nil
        }
    }
}

extension ActiveFilterLists {
    init?(encoded: String, activeLanguages: Set<String>, activeCommunityURLs: Set<String> = []) {
        guard let catalog = FilterListCatalogResponse(encodedCache: encoded) else { return nil }
        let jsonData = Data(encoded.utf8)

        var namesByURL: [String: String] = [:]
        for catalogEntry in catalog.lists {
            guard catalogEntry.entryType == .aiFilteringLanguage, let listURL = catalogEntry.resolvedURL else { continue }
            guard let language = catalogEntry.language, activeLanguages.contains(language) else { continue }
            namesByURL[listURL.absoluteString] = catalogEntry.displayName
        }

        let decoder = JSONDecoder()
        decoder.userInfo[.activeURLs] = Set(namesByURL.keys).union(activeCommunityURLs)
        let cachedLists: CachedLists
        do {
            cachedLists = try decoder.decode(CachedLists.self, from: jsonData)
        } catch {
            Log.error("cached lists don't decode, bytes: \(jsonData.count)", error: error)
            return nil
        }

        var aiLists: [ActiveFilterList] = []
        var communityLists: [ActiveFilterList] = []
        for cachedList in cachedLists.lists {
            guard let listRecords = cachedList.records else { continue }
            if let listName = namesByURL[cachedList.url] {
                aiLists.append(ActiveFilterList(name: listName, records: listRecords))
            }
            else if activeCommunityURLs.contains(cachedList.url) {
                let curatedEntry = catalog.curatedEntry(for: cachedList.url)
                let listName = curatedEntry?.name ?? FilterExportPayload.displayName(name: cachedList.name, url: cachedList.url)
                communityLists.append(ActiveFilterList(name: listName, records: listRecords))
            }
        }

        self.lists = aiLists + communityLists
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
    let name: String?
    let records: [FilterExportRecord]?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let activeURLs = decoder.userInfo[.activeURLs] as? Set<String> ?? []
        self.url = try container.decode(String.self, forKey: .url)

        guard activeURLs.contains(self.url) else {
            self.name = nil
            self.records = nil
            return
        }
        let payload = try container.decode(Payload.self, forKey: .payload)
        self.name = payload.name
        self.records = payload.filters
    }

    private struct Payload: Decodable {
        let name: String?
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
