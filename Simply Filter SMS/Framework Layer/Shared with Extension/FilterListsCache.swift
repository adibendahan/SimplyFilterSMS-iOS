//
//  FilterListsCache.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 29/10/2026.
//

import Foundation


struct FilterListsCache: Codable, Equatable {
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

extension FilterListsCache {
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

extension ActiveFilterLists {
    init?(encoded: String, activeLanguages: Set<String>) {
        guard let data = encoded.data(using: .utf8),
              let cachedCatalog = try? JSONDecoder().decode(CachedCatalog.self, from: data) else { return nil }

        var namesByURL: [String: String] = [:]
        for entry in cachedCatalog.catalog.lists {
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

private extension CodingUserInfoKey {
    static let activeURLs = CodingUserInfoKey(rawValue: "activeURLs")!
}
