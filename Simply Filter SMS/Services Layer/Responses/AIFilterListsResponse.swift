//
//  AIFilterListsResponse.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 28/10/2026.
//

import Foundation


struct AIFilterListsResponse: Codable, Equatable {
    static let formatIdentifier = "simply-filter-sms-ai-filters"
    static let currentVersion = 1

    let format: String
    let version: Int
    let revision: Int
    let updatedAt: Date
    let filterLists: [String: [FilterExportRecord]]
}

extension AIFilterListsResponse {
    var validatedLists: [String: [FilterTransferCandidate]] {
        return self.filterLists.mapValues { records in
            records
                .compactMap({ FilterTransferCandidate(record: $0) })
                .filter({ $0.type != .denyLanguage })
        }
    }

    init?(data: Data) {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let response = try? decoder.decode(Self.self, from: data),
              response.format == Self.formatIdentifier,
              (1...Self.currentVersion).contains(response.version) else { return nil }

        self = response
    }
}
