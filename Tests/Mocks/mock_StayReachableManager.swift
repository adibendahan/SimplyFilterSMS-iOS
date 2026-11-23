//
//  mock_StayReachableManager.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 24/11/2026.
//

import Foundation
@testable import Simply_Filter_SMS

class mock_StayReachableManager: StayReachableManagerProtocol {

    var rememberedSectionsCounter = 0
    var isAlreadyAllowedCounter = 0
    var saveCounter = 0

    var rememberedSectionsClosure: (([Filter]) -> ([StayReachableSection]))?
    var isAlreadyAllowedClosure: ((String, Filter?, [Filter]) -> (Bool))?
    var saveClosure: (([StayReachableSection]) -> ())?

    func rememberedSections(in filters: [Filter]) -> [StayReachableSection] {
        self.rememberedSectionsCounter += 1
        return self.rememberedSectionsClosure?(filters) ?? []
    }

    func isAlreadyAllowed(_ text: String, excluding ownFilter: Filter?, in filters: [Filter]) -> Bool {
        self.isAlreadyAllowedCounter += 1
        return self.isAlreadyAllowedClosure?(text, ownFilter, filters) ?? false
    }

    func save(_ sections: [StayReachableSection]) {
        self.saveCounter += 1
        self.saveClosure?(sections)
    }

    func resetCounters() {
        self.rememberedSectionsCounter = 0
        self.isAlreadyAllowedCounter = 0
        self.saveCounter = 0
    }
}
