//
//  mock_FilterImportExportManager.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 15/08/2026.
//

import Foundation
@testable import Simply_Filter_SMS

class mock_FilterImportExportManager: FilterImportExportManagerProtocol {

    var pendingPreview = FilterImportPreview.empty
    var lastImportResult: FilterImportResult?

    var exportPayloadCounter = 0
    var writeExportFileCounter = 0
    var deleteExportFileCounter = 0
    var isExportFileCounter = 0
    var readFileCounter = 0
    var previewImportCounter = 0
    var importFiltersCounter = 0

    var exportPayloadClosure: (() throws -> Data)?
    var writeExportFileClosure: (() throws -> URL)?
    var deleteExportFileClosure: ((URL) -> ())?
    var isExportFileClosure: ((URL) -> (Bool))?
    var readFileClosure: ((URL) throws -> Data)?
    var previewImportClosure: ((Data) throws -> FilterImportPreview)?
    var importCandidatesClosure: (([FilterImportCandidate]) -> FilterImportResult)?

    func exportPayload() throws -> Data {
        self.exportPayloadCounter += 1
        if let exportPayloadClosure = self.exportPayloadClosure {
            return try exportPayloadClosure()
        }
        return Data()
    }

    func writeExportFile() throws -> URL {
        self.writeExportFileCounter += 1
        if let writeExportFileClosure = self.writeExportFileClosure {
            return try writeExportFileClosure()
        }
        return FileManager.default.temporaryDirectory.appendingPathComponent("test.sfsfilters")
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

    func previewImport(data: Data) throws -> FilterImportPreview {
        self.previewImportCounter += 1
        if let previewImportClosure = self.previewImportClosure {
            return try previewImportClosure(data)
        }
        return FilterImportPreview.empty
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
        self.importFiltersCounter += 1
        if let importCandidatesClosure = self.importCandidatesClosure {
            let result = importCandidatesClosure(candidates)
            self.lastImportResult = result
            return result
        }
        let result = FilterImportResult(added: candidates.count,
                                        duplicateCount: self.pendingPreview.duplicateCount,
                                        invalidCount: self.pendingPreview.invalidCount)
        self.lastImportResult = result
        return result
    }

    func resetCounters() {
        self.exportPayloadCounter = 0
        self.writeExportFileCounter = 0
        self.deleteExportFileCounter = 0
        self.isExportFileCounter = 0
        self.readFileCounter = 0
        self.previewImportCounter = 0
        self.importFiltersCounter = 0
    }
}
