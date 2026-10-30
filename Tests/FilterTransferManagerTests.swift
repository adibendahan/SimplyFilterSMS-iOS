//
//  FilterTransferManagerTests.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 15/08/2026.
//

import Foundation
import XCTest
import NaturalLanguage
@testable import Simply_Filter_SMS

class FilterTransferManagerTests: XCTestCase {

    private var persistanceManager: PersistanceManager!
    private var testSubject: FilterTransferManager!

    //MARK: Test Lifecycle
    override func setUp() {
        super.setUp()
        self.persistanceManager = PersistanceManager(inMemory: true)
        self.testSubject = FilterTransferManager(persistanceManager: self.persistanceManager)
    }

    override func tearDown() {
        self.testSubject = nil
        self.persistanceManager = nil
        super.tearDown()
    }

    func test_roundTrip_denyAllowRegex_skipsLanguageBlocks() throws {
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

        let preview = try self.testSubject.queueImport(data: data)
        let result = self.testSubject.importFilters(preview.candidates)

        XCTAssertEqual(result.added, 3)
        XCTAssertEqual(result.duplicateCount, 0)
        XCTAssertEqual(result.invalidCount, 0)
        XCTAssertEqual(self.persistanceManager.fetchFilterRecords().count, 3)

        let deny = self.persistanceManager.fetchFilterRecords(for: .deny)
        XCTAssertEqual(deny.count, 2)
        XCTAssertTrue(deny.contains(where: { $0.text == "promo" && $0.filterTarget == .body && $0.filterMatching == .contains }))
        XCTAssertTrue(deny.contains(where: { $0.text == #"\d{5}"# && $0.filterMatching == .regex && $0.denyFolderType == .promotion }))

        let allow = self.persistanceManager.fetchFilterRecords(for: .allow)
        XCTAssertEqual(allow.count, 1)
        XCTAssertEqual(allow.first?.text, "Mom")
        XCTAssertEqual(allow.first?.filterMatching, .exact)
        XCTAssertEqual(allow.first?.filterCase, .caseSensitive)

        XCTAssertEqual(self.persistanceManager.fetchFilterRecords(for: .denyLanguage).count, 0)
    }

    func test_export_skipsLanguageBlocks() throws {
        self.persistanceManager.addFilter(text: "promo",
                                          type: .deny,
                                          denyFolder: .junk,
                                          filterTarget: .body,
                                          filterMatching: .contains,
                                          filterCase: .caseInsensitive)
        self.persistanceManager.addFilter(text: NLLanguage.english.filterText,
                                          type: .denyLanguage,
                                          denyFolder: .junk,
                                          filterTarget: .body,
                                          filterMatching: .contains,
                                          filterCase: .caseInsensitive)

        let preview = self.testSubject.queueExport()
        let object = try JSONSerialization.jsonObject(with: self.testSubject.exportPayload()) as? [String: Any]
        let filters = try XCTUnwrap(object?["filters"] as? [[String: Any]])

        XCTAssertEqual(preview.candidates.map({ $0.text }), ["promo"])
        XCTAssertEqual(filters.compactMap({ $0["type"] as? String }), ["deny"])
    }

    func test_import_fileExportedBy3_2() throws {
        let json = """
        {
          "format": "simply-filter-sms-filters",
          "version": 1,
          "exportedAt": "2026-08-15T18:00:00Z",
          "appVersion": "3.2.0",
          "filters": [
            { "text": "promo", "type": "deny", "folder": "promotion", "target": "body", "matching": "contains", "case": "insensitive" },
            { "text": "Mom", "type": "allow", "folder": "junk", "target": "sender", "matching": "exact", "case": "sensitive" },
            { "text": "\\\\d{5}", "type": "deny", "folder": "junk", "target": "all", "matching": "regex", "case": "sensitive" },
            { "text": "\(NLLanguage.english.filterText)", "type": "denyLanguage", "folder": "junk", "target": "body", "matching": "contains", "case": "insensitive" }
          ]
        }
        """

        let preview = try self.testSubject.previewImport(data: Data(json.utf8))

        XCTAssertEqual(preview.count, 3)
        XCTAssertEqual(preview.invalidCount, 0)
        XCTAssertTrue(preview.candidates.contains(where: { $0.text == "promo" && $0.denyFolder == .promotion }))
        XCTAssertTrue(preview.candidates.contains(where: { $0.text == "Mom" && $0.type == .allow && $0.filterCase == .caseSensitive }))
        XCTAssertTrue(preview.candidates.contains(where: { $0.text == #"\d{5}"# && $0.filterMatching == .regex }))
        XCTAssertFalse(preview.candidates.contains(where: { $0.type == .denyLanguage }))
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

        let preview = try self.testSubject.queueImport(data: data)
        let result = self.testSubject.importFilters(preview.candidates)

        XCTAssertEqual(result.added, 1)
        XCTAssertEqual(result.duplicateCount, 1)
        XCTAssertEqual(result.invalidCount, 0)
        let texts = Set(self.persistanceManager.fetchFilterRecords().compactMap({ $0.text }))
        XCTAssertEqual(texts, ["keep-me", "promo", "new-one"])
    }

    func test_forceClearBeforeImport_clearsListedTypesThenAdds() throws {
        self.persistanceManager.addFilter(text: "old-deny",
                                          type: .deny,
                                          denyFolder: .junk,
                                          filterTarget: .all,
                                          filterMatching: .contains,
                                          filterCase: .caseInsensitive)
        self.persistanceManager.addFilter(text: "keep-allow",
                                          type: .allow,
                                          denyFolder: .junk,
                                          filterTarget: .all,
                                          filterMatching: .contains,
                                          filterCase: .caseInsensitive)

        let data = try self.payload(filters: [
            record(text: "old-deny", type: "deny"),
            record(text: "fresh-deny", type: "deny")
        ], forceClearBeforeImport: ["deny"])

        let preview = try self.testSubject.queueImport(data: data)
        let result = self.testSubject.importFilters(preview.candidates)

        XCTAssertEqual(result.added, 2)
        XCTAssertEqual(result.duplicateCount, 0)
        let denyTexts = Set(self.persistanceManager.fetchFilterRecords(for: .deny).compactMap({ $0.text }))
        XCTAssertEqual(denyTexts, ["old-deny", "fresh-deny"])
        XCTAssertEqual(self.persistanceManager.fetchFilterRecords(for: .allow).first?.text, "keep-allow")
    }

    func test_forceClearBeforeImport_ignoresLanguageBlocks() throws {
        self.persistanceManager.addFilter(text: NLLanguage.english.filterText,
                                          type: .denyLanguage,
                                          denyFolder: .junk,
                                          filterTarget: .body,
                                          filterMatching: .contains,
                                          filterCase: .caseInsensitive)

        let data = try self.payload(filters: [
            record(text: "fresh-deny", type: "deny")
        ], forceClearBeforeImport: ["denyLanguage"])

        let preview = try self.testSubject.queueImport(data: data)
        let result = self.testSubject.importFilters(preview.candidates)

        XCTAssertEqual(result.added, 1)
        XCTAssertTrue(preview.forceClearTypes.isEmpty)
        XCTAssertEqual(self.persistanceManager.fetchFilterRecords(for: .denyLanguage).first?.text, NLLanguage.english.filterText)
    }

    func test_preview_skipsIntraFileDuplicates() throws {
        let data = try self.payload(filters: [
            record(text: "same", type: "deny"),
            record(text: "same", type: "deny")
        ])

        let preview = try self.testSubject.previewImport(data: data)

        XCTAssertEqual(preview.count, 1)
        XCTAssertEqual(preview.duplicateCount, 1)
        XCTAssertEqual(self.persistanceManager.fetchFilterRecords().count, 0)
    }

    func test_invalidJSON_throws() {
        XCTAssertThrowsError(try self.testSubject.previewImport(data: Data("not-json".utf8))) { error in
            XCTAssertEqual(error as? FilterTransferError, .invalidFile)
        }
    }

    func test_wrongFormat_throws() throws {
        let data = try self.payload(format: "other", filters: [])
        XCTAssertThrowsError(try self.testSubject.previewImport(data: data)) { error in
            XCTAssertEqual(error as? FilterTransferError, .invalidFile)
        }
    }

    func test_unsupportedVersion_throws() throws {
        let data = try self.payload(version: 99, filters: [record(text: "x", type: "deny")])
        XCTAssertThrowsError(try self.testSubject.previewImport(data: data)) { error in
            XCTAssertEqual(error as? FilterTransferError, .unsupportedVersion)
        }
    }

    func test_skipsInvalidRegex_ignoresLanguageBlocks() throws {
        let data = try self.payload(filters: [
            record(text: "[unclosed", type: "deny", matching: "regex"),
            record(text: NLLanguage.english.filterText, type: "denyLanguage", target: "body"),
            record(text: "ok", type: "deny")
        ])

        let preview = try self.testSubject.previewImport(data: data)

        XCTAssertEqual(preview.count, 1)
        XCTAssertEqual(preview.invalidCount, 1)
        XCTAssertEqual(preview.candidates.first?.text, "ok")
    }

    func test_import_regexIgnoresCase_othersRequireIt() throws {
        let data = try self.payload(filters: [
            record(text: #"\d{5}"#, type: "deny", matching: "regex", filterCase: nil),
            record(text: "(?i)^Apple$", type: "allow", matching: "regex", filterCase: "sensitive"),
            record(text: "promo", type: "deny", filterCase: nil)
        ])

        let preview = try self.testSubject.previewImport(data: data)

        XCTAssertEqual(preview.count, 2)
        XCTAssertEqual(preview.invalidCount, 1)
        XCTAssertTrue(preview.candidates.allSatisfy({ $0.filterMatching == .regex && $0.filterCase == .caseInsensitive }))
    }

    func test_export_omitsCaseForRegexOnly() throws {
        self.persistanceManager.addFilter(text: #"\d{5}"#,
                                          type: .deny,
                                          denyFolder: .junk,
                                          filterTarget: .all,
                                          filterMatching: .regex,
                                          filterCase: .caseSensitive)
        self.persistanceManager.addFilter(text: "promo",
                                          type: .deny,
                                          denyFolder: .junk,
                                          filterTarget: .body,
                                          filterMatching: .contains,
                                          filterCase: .caseSensitive)

        let object = try JSONSerialization.jsonObject(with: self.testSubject.exportPayload()) as? [String: Any]
        let filters = try XCTUnwrap(object?["filters"] as? [[String: Any]])

        XCTAssertNil(filters.first(where: { $0["matching"] as? String == "regex" })?["case"])
        XCTAssertEqual(filters.first(where: { $0["matching"] as? String == "contains" })?["case"] as? String, "sensitive")
    }

    func test_import_allowIgnoresFolder_othersRequireIt() throws {
        let data = try self.payload(filters: [
            record(text: "Mom", type: "allow", folder: nil),
            record(text: "Dad", type: "allow", folder: "promotion"),
            record(text: "promo", type: "deny", folder: nil)
        ])

        let preview = try self.testSubject.previewImport(data: data)

        XCTAssertEqual(preview.count, 2)
        XCTAssertEqual(preview.invalidCount, 1)
        XCTAssertTrue(preview.candidates.allSatisfy({ $0.type == .allow && $0.denyFolder == .junk }))
    }

    func test_export_omitsFolderForAllowOnly() throws {
        self.persistanceManager.addFilter(text: "Mom",
                                          type: .allow,
                                          denyFolder: .junk,
                                          filterTarget: .sender,
                                          filterMatching: .exact,
                                          filterCase: .caseInsensitive)
        self.persistanceManager.addFilter(text: "promo",
                                          type: .deny,
                                          denyFolder: .promotion,
                                          filterTarget: .body,
                                          filterMatching: .contains,
                                          filterCase: .caseInsensitive)

        let object = try JSONSerialization.jsonObject(with: self.testSubject.exportPayload()) as? [String: Any]
        let filters = try XCTUnwrap(object?["filters"] as? [[String: Any]])

        XCTAssertNil(filters.first(where: { $0["type"] as? String == "allow" })?["folder"])
        XCTAssertEqual(filters.first(where: { $0["type"] as? String == "deny" })?["folder"] as? String, "promotion")
    }

    func test_name_decodedWhenPresent_omittedFromExports() throws {
        let named = try FilterExportPayload(data: self.payload(name: "Community", filters: []))
        let unnamed = try FilterExportPayload(data: self.payload(filters: []))
        let exported = try JSONSerialization.jsonObject(with: self.testSubject.exportPayload()) as? [String: Any]

        XCTAssertEqual(named.name, "Community")
        XCTAssertNil(unnamed.name)
        XCTAssertNotNil(exported)
        XCTAssertNil(exported?["name"])
    }

    func test_revision_decodedWhenPresent_omittedFromExports() throws {
        let managed = try FilterExportPayload(data: self.payload(revision: 3, filters: []))
        let plain = try FilterExportPayload(data: self.payload(filters: []))
        let exported = try JSONSerialization.jsonObject(with: self.testSubject.exportPayload()) as? [String: Any]

        XCTAssertEqual(managed.revision, 3)
        XCTAssertNil(plain.revision)
        XCTAssertNotNil(exported)
        XCTAssertNil(exported?["revision"])
    }

    func test_importFilters_selectedSubsetOnly() throws {
        let data = try self.payload(filters: [
            record(text: "one", type: "deny"),
            record(text: "two", type: "deny")
        ])

        let preview = try self.testSubject.previewImport(data: data)
        XCTAssertEqual(preview.candidates.count, 2)

        let result = self.testSubject.importFilters(Array(preview.candidates.prefix(1)))

        XCTAssertEqual(result.added, 1)
        XCTAssertEqual(self.persistanceManager.fetchFilterRecords().count, 1)
        XCTAssertEqual(self.persistanceManager.fetchFilterRecords().first?.text, preview.candidates.first?.text)
    }

    func test_writeExportFile_createsSfsfilters() throws {
        self.persistanceManager.addFilter(text: "promo",
                                          type: .deny,
                                          denyFolder: .junk,
                                          filterTarget: .all,
                                          filterMatching: .contains,
                                          filterCase: .caseInsensitive)

        let preview = self.testSubject.queueExport()
        let url = try self.testSubject.writeExportFile(candidates: preview.candidates)
        XCTAssertEqual(url.pathExtension, kFilterExportFileExtension)
        XCTAssertTrue(url.lastPathComponent.range(of: #"^SimplyFilterSMS-filters-\d{4}-\d{2}-\d{2}-\d{4}\.sfsfilters$"#, options: .regularExpression) != nil)
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))

        let imported = try self.testSubject.previewImport(data: Data(contentsOf: url))
        XCTAssertEqual(imported.count, 0)
        XCTAssertEqual(imported.duplicateCount, 1)
        self.testSubject.deleteExportFile(at: url)
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func test_queueExport_listsLocalFilters() {
        self.persistanceManager.addFilter(text: "promo",
                                          type: .deny,
                                          denyFolder: .junk,
                                          filterTarget: .all,
                                          filterMatching: .contains,
                                          filterCase: .caseInsensitive)
        self.persistanceManager.addFilter(text: "Mom",
                                          type: .allow,
                                          denyFolder: .junk,
                                          filterTarget: .sender,
                                          filterMatching: .exact,
                                          filterCase: .caseSensitive)

        let preview = self.testSubject.queueExport()
        XCTAssertEqual(self.testSubject.pendingKind, .exportFilters)
        XCTAssertEqual(preview.candidates.count, 2)
        XCTAssertEqual(preview.duplicateCount, 0)
        XCTAssertEqual(preview.invalidCount, 0)
    }

    func test_writeExportFile_onlySelectedCandidates() throws {
        self.persistanceManager.addFilter(text: "promo",
                                          type: .deny,
                                          denyFolder: .junk,
                                          filterTarget: .all,
                                          filterMatching: .contains,
                                          filterCase: .caseInsensitive)
        self.persistanceManager.addFilter(text: "Mom",
                                          type: .allow,
                                          denyFolder: .junk,
                                          filterTarget: .sender,
                                          filterMatching: .exact,
                                          filterCase: .caseSensitive)

        let preview = self.testSubject.queueExport()
        let selected = preview.candidates.filter({ $0.type == .deny })
        let url = try self.testSubject.writeExportFile(candidates: selected)
        self.persistanceManager.deleteFilters(Set(self.persistanceManager.fetchFilterRecords()))
        let imported = try self.testSubject.previewImport(data: Data(contentsOf: url))
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported.candidates.first?.text, "promo")
        self.testSubject.deleteExportFile(at: url)
    }

    func test_deleteExportFile_ignoresNonExportAndNonTemp() throws {
        let jsonInTemp = FileManager.default.temporaryDirectory.appendingPathComponent("x.json")
        try Data("{}".utf8).write(to: jsonInTemp)
        self.testSubject.deleteExportFile(at: jsonInTemp)
        XCTAssertTrue(FileManager.default.fileExists(atPath: jsonInTemp.path))
        try FileManager.default.removeItem(at: jsonInTemp)

        let outsideTemp = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("x.sfsfilters")
        try Data("{}".utf8).write(to: outsideTemp)
        self.testSubject.deleteExportFile(at: outsideTemp)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outsideTemp.path))
        try FileManager.default.removeItem(at: outsideTemp)
    }

    func test_isExportFile_matchesExtension() {
        XCTAssertTrue(self.testSubject.isExportFile(URL(fileURLWithPath: "/tmp/x.sfsfilters")))
        XCTAssertTrue(self.testSubject.isExportFile(URL(fileURLWithPath: "/tmp/x.SFSFILTERS")))
        XCTAssertFalse(self.testSubject.isExportFile(URL(fileURLWithPath: "/tmp/x.json")))
    }

    func test_readFile_roundTrip() throws {
        let url = try self.testSubject.writeExportFile(candidates: [])
        let data = try self.testSubject.readFile(at: url)
        let preview = try self.testSubject.previewImport(data: data)
        XCTAssertEqual(preview.duplicateCount, 0)
        self.testSubject.deleteExportFile(at: url)
    }

    // MARK: - Helpers

    private func record(text: String,
                        type: String,
                        folder: String? = "junk",
                        target: String = "all",
                        matching: String = "contains",
                        filterCase: String? = "insensitive") -> [String: String] {
        var record = [
            "text": text,
            "type": type,
            "target": target,
            "matching": matching
        ]
        record["folder"] = folder
        record["case"] = filterCase
        return record
    }

    private func payload(format: String = FilterExportPayload.formatIdentifier,
                         version: Int = FilterExportPayload.currentVersion,
                         name: String? = nil,
                         revision: Int? = nil,
                         filters: [[String: String]],
                         forceClearBeforeImport: [String]? = nil) throws -> Data {
        var object: [String: Any] = [
            "format": format,
            "version": version,
            "exportedAt": "2026-08-15T18:00:00Z",
            "appVersion": "1.0",
            "filters": filters
        ]
        object["name"] = name
        object["revision"] = revision
        object["forceClearBeforeImport"] = forceClearBeforeImport
        return try JSONSerialization.data(withJSONObject: object)
    }
}
