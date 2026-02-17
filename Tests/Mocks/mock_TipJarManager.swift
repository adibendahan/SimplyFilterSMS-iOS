//
//  mock_TipJarManager.swift
//  Tests
//

import Foundation
import StoreKit
@testable import Simply_Filter_SMS

class mock_TipJarManager: TipJarManagerProtocol {

    var products: [Product] = []
    var isLoadingProducts: Bool = false

    var purchaseCounter = 0
    var purchaseClosure: ((Product) -> (TipPurchaseResult))?

    func purchase(_ product: Product) async -> TipPurchaseResult {
        self.purchaseCounter += 1
        return self.purchaseClosure?(product) ?? .userCancelled
    }

    func resetCounters() {
        self.purchaseCounter = 0
    }
}
