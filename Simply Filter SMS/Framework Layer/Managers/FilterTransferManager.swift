//
//  FilterTransferManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 15/08/2026.
//

import Foundation

class FilterTransferManager: FilterTransferManagerProtocol {

    private(set) var pendingPreview = FilterTransferPreview.empty
    private(set) var pendingKind: FilterTransferKind = .importFilters

    //MARK: - Initialization -
    init(persistenceManager: PersistenceManagerProtocol,
         fileManager: FileManager = .default) {
        self.persistenceManager = persistenceManager
        self.fileManager = fileManager
    }


    //MARK: - Public API (FilterTransferManagerProtocol) -
    func exportPayload() throws -> Data {
        return try self.encodePayload(records: self.storeRecords())
    }

    func writeExportFile(candidates: [FilterTransferCandidate]) throws -> URL {
        let exportRecords = candidates.map({ self.record(from: $0) })
        let data = try self.encodePayload(records: exportRecords)
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = "yyyy-MM-dd-HHmm"
        let filename = "SimplyFilterSMS-filters-\(formatter.string(from: Date())).\(kFilterExportFileExtension)"
        let url = self.fileManager.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        Log.debug("export file written, records: \(exportRecords.count), bytes: \(data.count), file: \(filename)")
        self.pendingExportURL = url
        return url
    }

    func queueExport() -> FilterTransferPreview {
        self.clearPendingExportFile()
        let preview = FilterTransferPreview(candidates: self.candidatesFromStore(),
                                          duplicateCount: 0,
                                          invalidCount: 0,
                                          forceClearTypes: [])
        Log.debug("export queued, filters: \(preview.candidates.count), storeFilters: \(self.persistenceManager.fetchFilterRecords().count)")
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
        let isExportFile = self.isExportFile(url)
        let isTemporary = url.path.hasPrefix(self.fileManager.temporaryDirectory.path)
        guard isExportFile, isTemporary else {
            Log.debug("export file kept, file: \(url.lastPathComponent), exportFile: \(isExportFile), temporary: \(isTemporary)")
            return
        }
        do {
            try self.fileManager.removeItem(at: url)
            Log.debug("export file deleted, file: \(url.lastPathComponent)")
        } catch {
            Log.error("could not delete the export file, file: \(url.lastPathComponent)", error: error)
        }
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
            Log.error("could not read the file, file: \(url.lastPathComponent), securityScoped: \(accessed)", error: error)
            throw FilterTransferError.invalidFile
        }
    }

    func previewImport(data: Data) throws -> FilterTransferPreview {
        let payload = try FilterExportPayload(data: data)
        let typesToClear = Self.forceClearTypes(from: payload)
        var accepted: [FilterTransferCandidate] = []
        var duplicateCount = 0
        var invalidCount = 0
        var skippedCount = 0
        var seenKeys = Set<String>()

        for record in payload.filters {
            if let recordType = FilterType(exportKey: record.type), !recordType.isTransferable {
                Log.debug("record not transferable, text: \(record.text), type: \(record.type) → skipped")
                skippedCount += 1
                continue
            }

            guard let candidate = FilterTransferCandidate(record: record), candidate.isImportable else {
                Log.debug("record invalid, text: \(record.text), type: \(record.type) → skipped")
                invalidCount += 1
                continue
            }

            let key = candidate.duplicateKey
            let isStoreDuplicate = !typesToClear.contains(candidate.type) &&
                self.persistenceManager.isDuplicateFilter(text: candidate.text,
                                                          filterTarget: candidate.filterTarget,
                                                          filterMatching: candidate.filterMatching,
                                                          filterCase: candidate.filterCase)
            if seenKeys.contains(key) || isStoreDuplicate {
                Log.debug("record duplicate, text: \(candidate.text), inFile: \(seenKeys.contains(key)), inStore: \(isStoreDuplicate) → skipped")
                duplicateCount += 1
                continue
            }

            seenKeys.insert(key)
            accepted.append(candidate)
        }

        let forceClearKeys = typesToClear.map(\.exportKey)
        Log.debug("import previewed, appVersion: \(payload.appVersion), version: \(payload.version), records: \(payload.filters.count), accepted: \(accepted.count), duplicates: \(duplicateCount), invalid: \(invalidCount), notTransferable: \(skippedCount), forceClear: \(forceClearKeys)")

        return FilterTransferPreview(candidates: accepted,
                                     duplicateCount: duplicateCount,
                                     invalidCount: invalidCount,
                                     forceClearTypes: typesToClear)
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
        for type in self.pendingPreview.forceClearTypes {
            let existing = self.persistenceManager.fetchFilterRecords(for: type)
            if !existing.isEmpty {
                Log.debug("force clear, type: \(type), filters: \(existing.count) → deleting")
                self.persistenceManager.deleteFilters(Set(existing))
            }
        }

        var added = 0

        for candidate in candidates {
            if self.persistenceManager.addFilter(text: candidate.text,
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
        Log.debug("import finished, selected: \(candidates.count), added: \(added), duplicates: \(self.pendingPreview.duplicateCount), invalid: \(self.pendingPreview.invalidCount)")
        self.lastImportResult = result
        return result
    }


    //MARK: - Private -
    private let persistenceManager: PersistenceManagerProtocol
    private let fileManager: FileManager
    private var lastImportResult: FilterTransferResult?
    private var pendingExportURL: URL?

    private func encodePayload(records: [FilterExportRecord]) throws -> Data {
        let payload = FilterExportPayload(format: FilterExportPayload.formatIdentifier,
                                          version: FilterExportPayload.currentVersion,
                                          exportedAt: Date(),
                                          appVersion: appVersion,
                                          name: nil,
                                          revision: nil,
                                          description: nil,
                                          homepage: nil,
                                          locale: nil,
                                          filters: records,
                                          forceClearBeforeImport: nil)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(payload)
    }

    private func storeRecords() -> [FilterExportRecord] {
        return self.candidatesFromStore().map({ self.record(from: $0) })
    }

    private func candidatesFromStore() -> [FilterTransferCandidate] {
        return self.persistenceManager.fetchFilterRecords().compactMap { filter in
            guard let text = filter.text, text.isEmpty == false else { return nil }
            guard filter.filterType.isTransferable else { return nil }
            return FilterTransferCandidate(id: filter.uuid ?? UUID(),
                                         text: text,
                                         type: filter.filterType,
                                         denyFolder: filter.messageFolder,
                                         filterTarget: filter.filterTarget,
                                         filterMatching: filter.filterMatching,
                                         filterCase: filter.filterCase)
        }
    }

    private func record(from candidate: FilterTransferCandidate) -> FilterExportRecord {
        return FilterExportRecord(text: candidate.text,
                                  type: candidate.type.exportKey,
                                  folder: candidate.denyFolder.exportKey(for: candidate.type),
                                  target: candidate.filterTarget.exportKey,
                                  matching: candidate.filterMatching.exportKey,
                                  caseSensitivity: candidate.filterCase.exportKey(for: candidate.filterMatching))
    }

    private func clearPendingExportFile() {
        if let url = self.pendingExportURL {
            self.deleteExportFile(at: url)
            self.pendingExportURL = nil
        }
    }

    private static func forceClearTypes(from payload: FilterExportPayload) -> Set<FilterType> {
        var forceClearTypes: Set<FilterType> = []

        for exportKey in payload.forceClearBeforeImport ?? [] {
            guard let filterType = FilterType(exportKey: exportKey), filterType.isTransferable else {
                Log.debug("force clear type not transferable, type: \(exportKey) → ignored")
                continue
            }
            forceClearTypes.insert(filterType)
        }

        return forceClearTypes
    }
}
