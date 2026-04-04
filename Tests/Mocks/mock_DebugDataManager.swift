//
//  mock_DebugDataManager.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 04/04/2026.
//

import XCTest
@testable import Simply_Filter_SMS

class mock_DebugDataManager: DebugDataManagerProtocol {
    var loadCallCount = 0
    var loadLangCode: String?

    func load() {
        loadCallCount += 1
    }

    func load(for langCode: String) {
        loadCallCount += 1
        loadLangCode = langCode
    }
}
