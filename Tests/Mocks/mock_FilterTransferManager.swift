//
//  mock_FilterTransferManager.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 15/08/2026.
//

import Foundation
@testable import Simply_Filter_SMS

class mock_FilterTransferManager: FilterTransferManagerProtocol {

    var pendingPreview = FilterTransferPreview.empty
    var pendingKind: FilterTransferKind = .importFilters
    var lastImportResult: FilterTransferResult?
    var pendingExportURL: URL?

    var exportPayloadCounter = 0
    var writeExportFileCounter = 0
    var queueExportCounter = 0
    var clearPendingExportCounter = 0
    var deleteExportFileCounter = 0
    var isExportFileCounter = 0
    var readFileCounter = 0
    var previewImportCounter = 0
    var importFiltersCounter = 0

    var exportPayloadClosure: (() throws -> Data)?
    var writeExportFileClosure: (([FilterTransferCandidate]) throws -> URL)?
    var queueExportClosure: (() -> FilterTransferPreview)?
    var deleteExportFileClosure: ((URL) -> ())?
    var isExportFileClosure: ((URL) -> (Bool))?
    var readFileClosure: ((URL) throws -> Data)?
    var previewImportClosure: ((Data) throws -> FilterTransferPreview)?
    var importCandidatesClosure: (([FilterTransferCandidate]) -> FilterTransferResult)?

    func exportPayload() throws -> Data {
        self.exportPayloadCounter += 1
        if let exportPayloadClosure = self.exportPayloadClosure {
            return try exportPayloadClosure()
        }
        return Data()
    }

    func writeExportFile(candidates: [FilterTransferCandidate]) throws -> URL {
        self.writeExportFileCounter += 1
        if let writeExportFileClosure = self.writeExportFileClosure {
            let url = try writeExportFileClosure(candidates)
            self.pendingExportURL = url
            return url
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("test.sfsfilters")
        self.pendingExportURL = url
        return url
    }

    func queueExport() -> FilterTransferPreview {
        self.queueExportCounter += 1
        let preview = self.queueExportClosure?() ?? self.pendingPreview
        self.pendingPreview = preview
        self.pendingKind = .exportFilters
        return preview
    }

    func clearPendingExport() {
        self.clearPendingExportCounter += 1
        self.pendingExportURL = nil
        if self.pendingKind == .exportFilters {
            self.pendingPreview = FilterTransferPreview.empty
            self.pendingKind = .importFilters
        }
    }

    func deleteExportFile(at url: URL) {
        self.deleteExportFileCounter += 1
        self.deleteExportFileClosure?(url)
    }

    func isExportFile(_ url: URL) -> Bool {
        self.isExportFileCounter += 1
        if let isExportFileClosure = self.isExportFileClosure {
            return isExportFileClosure(url)
        }
        return url.pathExtension.lowercased() == kFilterExportFileExtension
    }

    func readFile(at url: URL) throws -> Data {
        self.readFileCounter += 1
        if let readFileClosure = self.readFileClosure {
            return try readFileClosure(url)
        }
        return try Data(contentsOf: url)
    }

    func previewImport(data: Data) throws -> FilterTransferPreview {
        self.previewImportCounter += 1
        if let previewImportClosure = self.previewImportClosure {
            return try previewImportClosure(data)
        }
        return FilterTransferPreview.empty
    }

    func queueImport(data: Data) throws -> FilterTransferPreview {
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
        self.importFiltersCounter += 1
        if let importCandidatesClosure = self.importCandidatesClosure {
            let result = importCandidatesClosure(candidates)
            self.lastImportResult = result
            return result
        }
        let result = FilterTransferResult(added: candidates.count,
                                        duplicateCount: self.pendingPreview.duplicateCount,
                                        invalidCount: self.pendingPreview.invalidCount)
        self.lastImportResult = result
        return result
    }

    func resetCounters() {
        self.exportPayloadCounter = 0
        self.writeExportFileCounter = 0
        self.queueExportCounter = 0
        self.clearPendingExportCounter = 0
        self.deleteExportFileCounter = 0
        self.isExportFileCounter = 0
        self.readFileCounter = 0
        self.previewImportCounter = 0
        self.importFiltersCounter = 0
    }
}
