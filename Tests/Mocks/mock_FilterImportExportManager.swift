//
//  mock_FilterImportExportManager.swift
//  Simply Filter SMS Tests
//
//  Created by Adi Ben-Dahan on 15/08/2026.
//

import Foundation
@testable import Simply_Filter_SMS

class mock_FilterImportExportManager: FilterImportExportManagerProtocol {

    var exportPayloadCounter = 0
    var writeExportFileCounter = 0
    var isExportFileCounter = 0
    var readFileCounter = 0
    var previewImportCounter = 0
    var importFiltersCounter = 0

    var exportPayloadClosure: (() throws -> Data)?
    var writeExportFileClosure: (() throws -> URL)?
    var isExportFileClosure: ((URL) -> (Bool))?
    var readFileClosure: ((URL) throws -> Data)?
    var previewImportClosure: ((Data) throws -> FilterImportPreview)?
    var importFiltersClosure: ((Data) throws -> FilterImportResult)?
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
        return FilterImportPreview(toAdd: [], duplicateCount: 0, invalidCount: 0)
    }

    func importFilters(_ candidates: [FilterImportCandidate]) -> FilterImportResult {
        self.importFiltersCounter += 1
        if let importCandidatesClosure = self.importCandidatesClosure {
            return importCandidatesClosure(candidates)
        }
        return FilterImportResult(added: candidates.count, duplicateCount: 0, invalidCount: 0)
    }

    func importFilters(data: Data) throws -> FilterImportResult {
        self.importFiltersCounter += 1
        if let importFiltersClosure = self.importFiltersClosure {
            return try importFiltersClosure(data)
        }
        return FilterImportResult(added: 0, duplicateCount: 0, invalidCount: 0)
    }

    func resetCounters() {
        self.exportPayloadCounter = 0
        self.writeExportFileCounter = 0
        self.isExportFileCounter = 0
        self.readFileCounter = 0
        self.previewImportCounter = 0
        self.importFiltersCounter = 0
    }
}
