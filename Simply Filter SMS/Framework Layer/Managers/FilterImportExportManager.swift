//
//  FilterImportExportManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 15/08/2026.
//

import Foundation
import NaturalLanguage

class FilterImportExportManager: FilterImportExportManagerProtocol {

    private(set) var pendingPreview = FilterImportPreview.empty

    //MARK: - Initialization -
    init(persistanceManager: PersistanceManagerProtocol,
         fileManager: FileManager = .default) {
        self.persistanceManager = persistanceManager
        self.fileManager = fileManager
    }


    //MARK: - Public API (FilterImportExportManagerProtocol) -
    func exportPayload() throws -> Data {
        let records = self.persistanceManager.fetchFilterRecords().compactMap { filter -> FilterExportRecord? in
            guard let text = filter.text, text.isEmpty == false else { return nil }
            return FilterExportRecord(text: text,
                                      type: filter.filterType.exportKey,
                                      folder: filter.denyFolderType.exportKey,
                                      target: filter.filterTarget.exportKey,
                                      matching: filter.filterMatching.exportKey,
                                      caseSensitivity: filter.filterCase.exportKey)
        }

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

    func writeExportFile() throws -> URL {
        let data = try self.exportPayload()
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        let filename = "SimplyFilterSMS-filters-\(formatter.string(from: Date())).\(kFilterExportFileExtension)"
        let url = self.fileManager.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
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
            throw FilterImportExportError.invalidFile
        }
    }

    func previewImport(data: Data) throws -> FilterImportPreview {
        let payload = try self.decodePayload(data)
        var toAdd: [FilterImportCandidate] = []
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
            toAdd.append(candidate)
        }

        return FilterImportPreview(toAdd: toAdd, duplicateCount: duplicateCount, invalidCount: invalidCount)
    }

    func queueImport(data: Data) throws -> FilterImportPreview {
        let preview = try self.previewImport(data: data)
        self.pendingPreview = preview
        return preview
    }

    func clearPendingImport() -> FilterImportResult? {
        let result = self.lastImportResult
        self.pendingPreview = FilterImportPreview.empty
        self.lastImportResult = nil
        return result
    }

    func importFilters(_ candidates: [FilterImportCandidate]) -> FilterImportResult {
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

        let result = FilterImportResult(added: added,
                                        duplicateCount: self.pendingPreview.duplicateCount,
                                        invalidCount: self.pendingPreview.invalidCount)
        self.lastImportResult = result
        return result
    }


    //MARK: - Private -
    private let persistanceManager: PersistanceManagerProtocol
    private let fileManager: FileManager
    private var lastImportResult: FilterImportResult?

    private func decodePayload(_ data: Data) throws -> FilterExportPayload {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let payload = try decoder.decode(FilterExportPayload.self, from: data)
            guard payload.format == FilterExportPayload.formatIdentifier else {
                throw FilterImportExportError.invalidFile
            }
            guard payload.version >= 1 else {
                throw FilterImportExportError.invalidFile
            }
            guard payload.version <= FilterExportPayload.currentVersion else {
                throw FilterImportExportError.unsupportedVersion
            }
            return payload
        } catch let error as FilterImportExportError {
            throw error
        } catch {
            throw FilterImportExportError.invalidFile
        }
    }

    private static func candidate(from record: FilterExportRecord) -> FilterImportCandidate? {
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

        return FilterImportCandidate(text: text,
                                     type: type,
                                     denyFolder: folder,
                                     filterTarget: target,
                                     filterMatching: matching,
                                     filterCase: filterCase)
    }
}
