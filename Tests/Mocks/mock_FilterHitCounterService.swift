//
//  mock_FilterHitCounterService.swift
//  Tests
//

import Foundation
@testable import Simply_Filter_SMS

class mock_FilterHitCounterService: FilterHitCounterServiceProtocol {

    var incrementCountCounter = 0
    var countsCounter = 0

    var incrementCountClosure: ((String) -> ())?
    var countsClosure: (() -> [String: Int])?

    func incrementCount(for filterID: String) {
        self.incrementCountCounter += 1
        self.incrementCountClosure?(filterID)
    }

    func counts() -> [String: Int] {
        self.countsCounter += 1
        return self.countsClosure?() ?? [:]
    }

    func resetCounters() {
        self.incrementCountCounter = 0
        self.countsCounter = 0
    }
}
