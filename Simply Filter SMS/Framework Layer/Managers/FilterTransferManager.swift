//
//  FilterTransferManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 15/08/2026.
//

import Foundation
import NaturalLanguage

class FilterTransferManager: FilterTransferManagerProtocol {

    private(set) var pendingPreview = FilterTransferPreview.empty
    private(set) var pendingKind: FilterTransferKind = .importFilters

    //MARK: - Initialization -
    init(persistanceManager: PersistanceManagerProtocol,
         fileManager: FileManager = .default) {
        self.persistanceManager = persistanceManager
        self.fileManager = fileManager
    }


    //MARK: - Public API (FilterTransferManagerProtocol) -
    func exportPayload() throws -> Data {
        return try self.encodePayload(records: self.storeRecords())
    }

    func writeExportFile(candidates: [FilterTransferCandidate]) throws -> URL {
        let data = try self.encodePayload(records: candidates.map({ self.record(from: $0) }))
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        let filename = "SimplyFilterSMS-filters-\(formatter.string(from: Date())).\(kFilterExportFileExtension)"
        let url = self.fileManager.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        self.pendingExportURL = url
        return url
    }

    func queueExport() -> FilterTransferPreview {
        self.clearPendingExportFile()
        let preview = FilterTransferPreview(candidates: self.candidatesFromStore(),
                                          duplicateCount: 0,
                                          invalidCount: 0)
        self.pendingPreview = preview
        self.pendingKind = .exportFilters
        return preview
    }

    func clearPendingExport() {
        self.clearPendingExportFile()
        if self.pendingKind == .exportFilters {
            self.pendingPreview = FilterTransferPreview.empty
            self.pendingKind = .importFilters
        }
    }

    func deleteExportFile(at url: URL) {
        guard self.isExportFile(url) else { return }
        guard url.path.hasPrefix(self.fileManager.temporaryDirectory.path) else { return }
        try? self.fileManager.removeItem(at: url)
    }

    func isExportFile(_ url: URL) -> Bool {
        return url.pathExtension.lowercased() == kFilterExportFileExtension
    }

    func readFile(at url: URL) throws -> Data {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed {
                url.stopAccessingSecurityScopedResource()
            }
        }

        do {
            return try Data(contentsOf: url)
        } catch {
            throw FilterTransferError.invalidFile
        }
    }

    func previewImport(data: Data) throws -> FilterTransferPreview {
        let payload = try self.decodePayload(data)
        var accepted: [FilterTransferCandidate] = []
        var duplicateCount = 0
        var invalidCount = 0
        var seenKeys = Set<String>()

        for record in payload.filters {
            guard let candidate = Self.candidate(from: record) else {
                invalidCount += 1
                continue
            }

            let key = candidate.duplicateKey
            if seenKeys.contains(key) ||
                self.persistanceManager.isDuplicateFilter(text: candidate.text,
                                                          filterTarget: candidate.filterTarget,
                                                          filterMatching: candidate.filterMatching,
                                                          filterCase: candidate.filterCase) {
                duplicateCount += 1
                continue
            }

            seenKeys.insert(key)
            accepted.append(candidate)
        }

        return FilterTransferPreview(candidates: accepted, duplicateCount: duplicateCount, invalidCount: invalidCount)
    }

    func queueImport(data: Data) throws -> FilterTransferPreview {
        self.clearPendingExportFile()
        let preview = try self.previewImport(data: data)
        self.pendingPreview = preview
        self.pendingKind = .importFilters
        return preview
    }

    func clearPendingImport() -> FilterTransferResult? {
        let result = self.lastImportResult
        self.pendingPreview = FilterTransferPreview.empty
        self.lastImportResult = nil
        self.pendingKind = .importFilters
        return result
    }

    func importFilters(_ candidates: [FilterTransferCandidate]) -> FilterTransferResult {
        var added = 0

        for candidate in candidates {
            if self.persistanceManager.addFilter(text: candidate.text,
                                                 type: candidate.type,
                                                 denyFolder: candidate.denyFolder,
                                                 filterTarget: candidate.filterTarget,
                                                 filterMatching: candidate.filterMatching,
                                                 filterCase: candidate.filterCase) != nil {
                added += 1
            }
        }

        let result = FilterTransferResult(added: added,
                                        duplicateCount: self.pendingPreview.duplicateCount,
                                        invalidCount: self.pendingPreview.invalidCount)
        self.lastImportResult = result
        return result
    }


    //MARK: - Private -
    private let persistanceManager: PersistanceManagerProtocol
    private let fileManager: FileManager
    private var lastImportResult: FilterTransferResult?
    private var pendingExportURL: URL?

    private func encodePayload(records: [FilterExportRecord]) throws -> Data {
        let payload = FilterExportPayload(format: FilterExportPayload.formatIdentifier,
                                          version: FilterExportPayload.currentVersion,
                                          exportedAt: Date(),
                                          appVersion: appVersion,
                                          filters: records)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    private func storeRecords() -> [FilterExportRecord] {
        return self.candidatesFromStore().map({ self.record(from: $0) })
    }

    private func candidatesFromStore() -> [FilterTransferCandidate] {
        return self.persistanceManager.fetchFilterRecords().compactMap { filter in
            guard let text = filter.text, text.isEmpty == false else { return nil }
            return FilterTransferCandidate(id: filter.uuid ?? UUID(),
                                         text: text,
                                         type: filter.filterType,
                                         denyFolder: filter.denyFolderType,
                                         filterTarget: filter.filterTarget,
                                         filterMatching: filter.filterMatching,
                                         filterCase: filter.filterCase)
        }
    }

    private func record(from candidate: FilterTransferCandidate) -> FilterExportRecord {
        return FilterExportRecord(text: candidate.text,
                                  type: candidate.type.exportKey,
                                  folder: candidate.denyFolder.exportKey,
                                  target: candidate.filterTarget.exportKey,
                                  matching: candidate.filterMatching.exportKey,
                                  caseSensitivity: candidate.filterCase.exportKey)
    }

    private func clearPendingExportFile() {
        if let url = self.pendingExportURL {
            self.deleteExportFile(at: url)
            self.pendingExportURL = nil
        }
    }

    private func decodePayload(_ data: Data) throws -> FilterExportPayload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let payload = try decoder.decode(FilterExportPayload.self, from: data)
            guard payload.format == FilterExportPayload.formatIdentifier else {
                throw FilterTransferError.invalidFile
            }
            guard payload.version >= 1 else {
                throw FilterTransferError.invalidFile
            }
            guard payload.version <= FilterExportPayload.currentVersion else {
                throw FilterTransferError.unsupportedVersion
            }
            return payload
        } catch let error as FilterTransferError {
            throw error
        } catch {
            throw FilterTransferError.invalidFile
        }
    }

    private static func candidate(from record: FilterExportRecord) -> FilterTransferCandidate? {
        guard let text = record.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              text.count >= kMinimumFilterLength,
              let type = FilterType(exportKey: record.type),
              let folder = DenyFolderType(exportKey: record.folder),
              let target = FilterTarget(exportKey: record.target),
              let matching = FilterMatching(exportKey: record.matching),
              let filterCase = FilterCase(exportKey: record.caseSensitivity) else {
            return nil
        }

        if type == .denyLanguage {
            let language = NLLanguage(filterText: text)
            guard language != .undetermined else { return nil }
        }

        if matching == .regex {
            guard (try? Regex(text)) != nil else { return nil }
        }

        return FilterTransferCandidate(text: text,
                                     type: type,
                                     denyFolder: folder,
                                     filterTarget: target,
                                     filterMatching: matching,
                                     filterCase: filterCase)
    }
}
