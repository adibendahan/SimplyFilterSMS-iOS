//
//  mock_DebugDataManager.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 04/04/2026.
//

import XCTest
@testable import Simply_Filter_SMS

class mock_DebugDataManager: DebugDataManagerProtocol {

    var loadCounter = 0
    var loadForLangCodeCounter = 0
    var expireFilterListsCacheCounter = 0

    var loadClosure: (() -> ())?
    var loadForLangCodeClosure: ((String) -> ())?
    var expireFilterListsCacheClosure: (() -> ())?

    func load() {
        self.loadCounter += 1
        self.loadClosure?()
    }

    func load(for langCode: String) {
        self.loadForLangCodeCounter += 1
        self.loadForLangCodeClosure?(langCode)
    }

    func expireFilterListsCache() {
        self.expireFilterListsCacheCounter += 1
        self.expireFilterListsCacheClosure?()
    }

    func resetCounters() {
        self.loadCounter = 0
        self.loadForLangCodeCounter = 0
        self.expireFilterListsCacheCounter = 0
    }
}
