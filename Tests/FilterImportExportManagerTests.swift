//
//  FilterImportExportManagerTests.swift
//  Simply Filter SMS Tests
//
//  Created by Adi Ben-Dahan on 15/08/2026.
//

import Foundation
import XCTest
import NaturalLanguage
@testable import Simply_Filter_SMS

class FilterImportExportManagerTests: XCTestCase {

    private var persistanceManager: PersistanceManager!
    private var testSubject: FilterImportExportManager!

    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()
        self.persistanceManager = PersistanceManager(inMemory: true)
        self.testSubject = FilterImportExportManager(persistanceManager: self.persistanceManager)
    }

    override func tearDown() {
        self.testSubject = nil
        self.persistanceManager = nil
        super.tearDown()
    }

    func test_roundTrip_denyAllowRegexLanguage() throws {
        self.persistanceManager.addFilter(text: "promo",
                                          type: .deny,
                                          denyFolder: .junk,
                                          filterTarget: .body,
                                          filterMatching: .contains,
                                          filterCase: .caseInsensitive)
        self.persistanceManager.addFilter(text: "Mom",
                                          type: .allow,
                                          denyFolder: .junk,
                                          filterTarget: .sender,
                                          filterMatching: .exact,
                                          filterCase: .caseSensitive)
        self.persistanceManager.addFilter(text: #"\d{5}"#,
                                          type: .deny,
                                          denyFolder: .promotion,
                                          filterTarget: .all,
                                          filterMatching: .regex,
                                          filterCase: .caseInsensitive)
        self.persistanceManager.addFilter(text: NLLanguage.english.filterText,
                                          type: .denyLanguage,
                                          denyFolder: .junk,
                                          filterTarget: .body,
                                          filterMatching: .contains,
                                          filterCase: .caseInsensitive)

        let data = try self.testSubject.exportPayload()
        self.persistanceManager.deleteFilters(Set(self.persistanceManager.fetchFilterRecords()))
        XCTAssertEqual(self.persistanceManager.fetchFilterRecords().count, 0)

        let result = try self.testSubject.importFilters(data: data)

        XCTAssertEqual(result.added, 4)
        XCTAssertEqual(result.duplicateCount, 0)
        XCTAssertEqual(result.invalidCount, 0)
        XCTAssertEqual(self.persistanceManager.fetchFilterRecords().count, 4)

        let deny = self.persistanceManager.fetchFilterRecords(for: .deny)
        XCTAssertEqual(deny.count, 2)
        XCTAssertTrue(deny.contains(where: { $0.text == "promo" && $0.filterTarget == .body && $0.filterMatching == .contains }))
        XCTAssertTrue(deny.contains(where: { $0.text == #"\d{5}"# && $0.filterMatching == .regex && $0.denyFolderType == .promotion }))

        let allow = self.persistanceManager.fetchFilterRecords(for: .allow)
        XCTAssertEqual(allow.count, 1)
        XCTAssertEqual(allow.first?.text, "Mom")
        XCTAssertEqual(allow.first?.filterMatching, .exact)
        XCTAssertEqual(allow.first?.filterCase, .caseSensitive)

        let languages = self.persistanceManager.fetchFilterRecords(for: .denyLanguage)
        XCTAssertEqual(languages.count, 1)
        XCTAssertEqual(languages.first?.text, NLLanguage.english.filterText)
    }

    func test_import_skipsDuplicatesAndDoesNotDeleteExisting() throws {
        self.persistanceManager.addFilter(text: "keep-me",
                                          type: .allow,
                                          denyFolder: .junk,
                                          filterTarget: .all,
                                          filterMatching: .contains,
                                          filterCase: .caseInsensitive)
        self.persistanceManager.addFilter(text: "promo",
                                          type: .deny,
                                          denyFolder: .junk,
                                          filterTarget: .all,
                                          filterMatching: .contains,
                                          filterCase: .caseInsensitive)

        let data = try self.payload(filters: [
            record(text: "promo", type: "deny"),
            record(text: "new-one", type: "deny")
        ])

        let result = try self.testSubject.importFilters(data: data)

        XCTAssertEqual(result.added, 1)
        XCTAssertEqual(result.duplicateCount, 1)
        XCTAssertEqual(result.invalidCount, 0)
        let texts = Set(self.persistanceManager.fetchFilterRecords().compactMap({ $0.text }))
        XCTAssertEqual(texts, ["keep-me", "promo", "new-one"])
    }

    func test_preview_skipsIntraFileDuplicates() throws {
        let data = try self.payload(filters: [
            record(text: "same", type: "deny"),
            record(text: "same", type: "deny")
        ])

        let preview = try self.testSubject.previewImport(data: data)

        XCTAssertEqual(preview.addedCount, 1)
        XCTAssertEqual(preview.duplicateCount, 1)
        XCTAssertEqual(self.persistanceManager.fetchFilterRecords().count, 0)
    }

    func test_invalidJSON_throws() {
        XCTAssertThrowsError(try self.testSubject.previewImport(data: Data("not-json".utf8))) { error in
            XCTAssertEqual(error as? FilterImportExportError, .invalidFile)
        }
    }

    func test_wrongFormat_throws() throws {
        let data = try self.payload(format: "other", filters: [])
        XCTAssertThrowsError(try self.testSubject.previewImport(data: data)) { error in
            XCTAssertEqual(error as? FilterImportExportError, .invalidFile)
        }
    }

    func test_unsupportedVersion_throws() throws {
        let data = try self.payload(version: 99, filters: [record(text: "x", type: "deny")])
        XCTAssertThrowsError(try self.testSubject.previewImport(data: data)) { error in
            XCTAssertEqual(error as? FilterImportExportError, .unsupportedVersion)
        }
    }

    func test_skipsInvalidRegexAndUnknownLanguage() throws {
        let data = try self.payload(filters: [
            record(text: "[unclosed", type: "deny", matching: "regex"),
            record(text: "$lang:klingon", type: "denyLanguage", target: "body"),
            record(text: "ok", type: "deny")
        ])

        let preview = try self.testSubject.previewImport(data: data)

        XCTAssertEqual(preview.addedCount, 1)
        XCTAssertEqual(preview.invalidCount, 2)
        XCTAssertEqual(preview.toAdd.first?.text, "ok")
    }

    func test_importFilters_selectedSubsetOnly() throws {
        let data = try self.payload(filters: [
            record(text: "one", type: "deny"),
            record(text: "two", type: "deny")
        ])

        let preview = try self.testSubject.previewImport(data: data)
        XCTAssertEqual(preview.toAdd.count, 2)

        let result = self.testSubject.importFilters(Array(preview.toAdd.prefix(1)))

        XCTAssertEqual(result.added, 1)
        XCTAssertEqual(self.persistanceManager.fetchFilterRecords().count, 1)
        XCTAssertEqual(self.persistanceManager.fetchFilterRecords().first?.text, preview.toAdd.first?.text)
    }

    func test_writeExportFile_createsSfsfilters() throws {
        self.persistanceManager.addFilter(text: "promo",
                                          type: .deny,
                                          denyFolder: .junk,
                                          filterTarget: .all,
                                          filterMatching: .contains,
                                          filterCase: .caseInsensitive)

        let url = try self.testSubject.writeExportFile()
        XCTAssertEqual(url.pathExtension, kFilterExportFileExtension)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        let imported = try self.testSubject.previewImport(data: Data(contentsOf: url))
        XCTAssertEqual(imported.addedCount, 0)
        XCTAssertEqual(imported.duplicateCount, 1)
    }

    func test_isExportFile_matchesExtension() {
        XCTAssertTrue(self.testSubject.isExportFile(URL(fileURLWithPath: "/tmp/x.sfsfilters")))
        XCTAssertTrue(self.testSubject.isExportFile(URL(fileURLWithPath: "/tmp/x.SFSFILTERS")))
        XCTAssertFalse(self.testSubject.isExportFile(URL(fileURLWithPath: "/tmp/x.json")))
    }

    func test_readFile_roundTrip() throws {
        let url = try self.testSubject.writeExportFile()
        let data = try self.testSubject.readFile(at: url)
        let preview = try self.testSubject.previewImport(data: data)
        XCTAssertEqual(preview.duplicateCount, 0)
    }

    // MARK: - Helpers

    private func record(text: String,
                        type: String,
                        folder: String = "junk",
                        target: String = "all",
                        matching: String = "contains",
                        filterCase: String = "insensitive") -> [String: String] {
        return [
            "text": text,
            "type": type,
            "folder": folder,
            "target": target,
            "matching": matching,
            "case": filterCase
        ]
    }

    private func payload(format: String = FilterExportPayload.formatIdentifier,
                         version: Int = FilterExportPayload.currentVersion,
                         filters: [[String: String]]) throws -> Data {
        let object: [String: Any] = [
            "format": format,
            "version": version,
            "exportedAt": "2026-08-15T18:00:00Z",
            "appVersion": "1.0",
            "filters": filters
        ]
        return try JSONSerialization.data(withJSONObject: object)
    }
}
