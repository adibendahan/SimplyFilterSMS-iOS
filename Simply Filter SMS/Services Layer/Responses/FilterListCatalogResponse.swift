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
    static let currentVersion = 1

    let format: String
    let version: Int
    let lists: [FilterListCatalogEntry]
}

struct FilterListCatalogEntry: Codable, Equatable {
    let id: String
    let name: String
    let url: String
    let language: String?
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
}

extension FilterListCatalogEntry {
    var resolvedURL: URL? {
        return URL(string: self.url, relativeTo: .filterListCatalogURL)?.absoluteURL
    }

    var displayName: String {
        guard let language = self.language else { return self.name }
        let nlLanguage = NLLanguage(rawValue: language)
        return nlLanguage.localizedName ?? self.name
    }
}
