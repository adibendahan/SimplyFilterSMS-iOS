//
//  FilterHitCounterService.swift
//  Simply Filter SMS
//

import Foundation


protocol FilterHitCounterServiceProtocol {
    func incrementCount(for filterID: String)
    func counts() -> [String: Int]
}


class FilterHitCounterService: FilterHitCounterServiceProtocol {
    private let defaults: UserDefaults
    private let key = "filterHitCounts"

    init(defaults: UserDefaults = UserDefaults(suiteName: kAppGroupContainer) ?? .standard) {
        self.defaults = defaults
    }

    func incrementCount(for filterID: String) {
        var current = defaults.dictionary(forKey: key) as? [String: Int] ?? [:]
        current[filterID, default: 0] += 1
        defaults.set(current, forKey: key)
    }

    func counts() -> [String: Int] {
        return defaults.dictionary(forKey: key) as? [String: Int] ?? [:]
    }
}
