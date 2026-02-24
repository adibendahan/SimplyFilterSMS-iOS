//
//  TipJarManagerProtocol.swift
//  Simply Filter SMS
//

import StoreKit

enum TipPurchaseResult {
    case success(TipTier)
    case userCancelled
    case pending
    case failure(Error)
}

protocol TipJarManagerProtocol {
    @MainActor var products: [Product] { get }
    @MainActor var isLoadingProducts: Bool { get }
    func purchase(_ product: Product) async -> TipPurchaseResult
}
