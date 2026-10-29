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
