//
//  FilterImportExportManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 15/08/2026.
//

import Foundation


enum FilterImportExportError: Error, Equatable {
    case invalidFile
    case unsupportedVersion
}

struct FilterExportPayload: Codable, Equatable {
    static let formatIdentifier = "simply-filter-sms-filters"
    static let currentVersion = 1

    let format: String
    let version: Int
    let exportedAt: Date
    let appVersion: String
    let filters: [FilterExportRecord]
}

struct FilterExportRecord: Codable, Equatable {
    let text: String?
    let type: String?
    let folder: String?
    let target: String?
    let matching: String?
    let caseSensitivity: String?

    enum CodingKeys: String, CodingKey {
        case text, type, folder, target, matching
        case caseSensitivity = "case"
    }
}

struct FilterImportCandidate: Equatable, Identifiable {
    let id: UUID
    let text: String
    let type: FilterType
    let denyFolder: DenyFolderType
    let filterTarget: FilterTarget
    let filterMatching: FilterMatching
    let filterCase: FilterCase

    init(id: UUID = UUID(),
         text: String,
         type: FilterType,
         denyFolder: DenyFolderType,
         filterTarget: FilterTarget,
         filterMatching: FilterMatching,
         filterCase: FilterCase) {
        self.id = id
        self.text = text
        self.type = type
        self.denyFolder = denyFolder
        self.filterTarget = filterTarget
        self.filterMatching = filterMatching
        self.filterCase = filterCase
    }

    var duplicateKey: String {
        return "\(self.text)|\(self.filterTarget.rawValue)|\(self.filterMatching.rawValue)|\(self.filterCase.rawValue)"
    }
}

struct FilterImportPreview: Equatable {
    let toAdd: [FilterImportCandidate]
    let duplicateCount: Int
    let invalidCount: Int

    var addedCount: Int { return self.toAdd.count }
    var skippedCount: Int { return self.duplicateCount + self.invalidCount }

    func count(for type: FilterType) -> Int {
        return self.toAdd.filter({ $0.type == type }).count
    }
}

struct FilterImportResult: Equatable {
    let added: Int
    let duplicateCount: Int
    let invalidCount: Int

    var skippedCount: Int { return self.duplicateCount + self.invalidCount }
}

protocol FilterImportExportManagerProtocol {
    func exportPayload() throws -> Data
    func writeExportFile() throws -> URL
    func isExportFile(_ url: URL) -> Bool
    func readFile(at url: URL) throws -> Data
    func previewImport(data: Data) throws -> FilterImportPreview
    func importFilters(_ candidates: [FilterImportCandidate]) -> FilterImportResult
    func importFilters(data: Data) throws -> FilterImportResult
}


extension FilterType {
    var exportKey: String {
        switch self {
        case .deny:
            return "deny"
        case .allow:
            return "allow"
        case .denyLanguage:
            return "denyLanguage"
        }
    }

    init?(exportKey: String?) {
        switch exportKey {
        case "deny":
            self = .deny
        case "allow":
            self = .allow
        case "denyLanguage":
            self = .denyLanguage
        default:
            return nil
        }
    }
}

extension DenyFolderType {
    var exportKey: String {
        switch self {
        case .junk:
            return "junk"
        case .transaction:
            return "transaction"
        case .promotion:
            return "promotion"
        }
    }

    init?(exportKey: String?) {
        switch exportKey {
        case "junk":
            self = .junk
        case "transaction":
            self = .transaction
        case "promotion":
            self = .promotion
        default:
            return nil
        }
    }
}

extension FilterTarget {
    var exportKey: String {
        switch self {
        case .all:
            return "all"
        case .sender:
            return "sender"
        case .body:
            return "body"
        }
    }

    init?(exportKey: String?) {
        switch exportKey {
        case "all":
            self = .all
        case "sender":
            self = .sender
        case "body":
            self = .body
        default:
            return nil
        }
    }
}

extension FilterMatching {
    var exportKey: String {
        switch self {
        case .contains:
            return "contains"
        case .exact:
            return "exact"
        case .regex:
            return "regex"
        }
    }

    init?(exportKey: String?) {
        switch exportKey {
        case "contains":
            self = .contains
        case "exact":
            self = .exact
        case "regex":
            self = .regex
        default:
            return nil
        }
    }
}

extension FilterCase {
    var exportKey: String {
        switch self {
        case .caseInsensitive:
            return "insensitive"
        case .caseSensitive:
            return "sensitive"
        }
    }

    init?(exportKey: String?) {
        switch exportKey {
        case "insensitive":
            self = .caseInsensitive
        case "sensitive":
            self = .caseSensitive
        default:
            return nil
        }
    }
}
