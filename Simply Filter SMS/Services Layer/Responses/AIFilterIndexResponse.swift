//
//  AIFilterIndexResponse.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 28/10/2026.
//

import Foundation


struct AIFilterIndexResponse: Codable, Equatable {
    static let formatIdentifier = "simply-filter-sms-ai-index"
    static let currentVersion = 1

    let format: String
    let version: Int
    let lists: [String]
}

extension AIFilterIndexResponse {
    init?(data: Data) {
        guard let response = try? JSONDecoder().decode(Self.self, from: data),
              response.format == Self.formatIdentifier,
              (1...Self.currentVersion).contains(response.version) else { return nil }

        self = response
    }
}
