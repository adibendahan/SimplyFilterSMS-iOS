//
//  FilterTransferManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 15/08/2026.
//

import Foundation
import NaturalLanguage


enum FilterTransferError: Error, Equatable {
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
    let forceClearBeforeImport: [String]?
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

struct ExportFile: Identifiable {
    let id = UUID()
    let url: URL
}

struct FilterTransferCandidate: Equatable, Identifiable {
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

    init?(record: FilterExportRecord) {
        guard let text = record.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              text.count >= kMinimumFilterLength,
              let type = FilterType(exportKey: record.type),
              let folder = DenyFolderType(exportKey: record.folder),
              let target = FilterTarget(exportKey: record.target),
              let matching = FilterMatching(exportKey: record.matching),
              let filterCase = FilterCase(exportKey: record.caseSensitivity, for: matching) else {
            return nil
        }

        if type == .denyLanguage {
            let language = NLLanguage(filterText: text)
            guard language != .undetermined else { return nil }
        }

        if matching == .regex {
            guard (try? Regex(text)) != nil else { return nil }
        }

        self.init(text: text,
                  type: type,
                  denyFolder: folder,
                  filterTarget: target,
                  filterMatching: matching,
                  filterCase: filterCase)
    }

    var duplicateKey: String {
        return "\(self.text)|\(self.filterTarget.rawValue)|\(self.filterMatching.rawValue)|\(self.filterCase.rawValue)"
    }
}

struct FilterTransferPreview: Equatable {
    static let empty = FilterTransferPreview(candidates: [], duplicateCount: 0, invalidCount: 0, forceClearTypes: [])

    let candidates: [FilterTransferCandidate]
    let duplicateCount: Int
    let invalidCount: Int
    let forceClearTypes: Set<FilterType>

    var count: Int { return self.candidates.count }
    var skippedCount: Int { return self.duplicateCount + self.invalidCount }
}

struct FilterTransferResult: Equatable {
    let added: Int
    let duplicateCount: Int
    let invalidCount: Int

    var skippedCount: Int { return self.duplicateCount + self.invalidCount }
}

enum FilterTransferKind: Equatable {
    case importFilters
    case exportFilters
}

protocol FilterTransferManagerProtocol {
    var pendingPreview: FilterTransferPreview { get }
    var pendingKind: FilterTransferKind { get }

    func exportPayload() throws -> Data
    func writeExportFile(candidates: [FilterTransferCandidate]) throws -> URL
    func queueExport() -> FilterTransferPreview
    func clearPendingExport()
    func deleteExportFile(at url: URL)
    func isExportFile(_ url: URL) -> Bool
    func readFile(at url: URL) throws -> Data
    func previewImport(data: Data) throws -> FilterTransferPreview
    func queueImport(data: Data) throws -> FilterTransferPreview
    func clearPendingImport() -> FilterTransferResult?
    func importFilters(_ candidates: [FilterTransferCandidate]) -> FilterTransferResult
}
