//
//  TipJarManager.swift
//  Simply Filter SMS
//

import StoreKit
import OSLog

class TipJarManager: TipJarManagerProtocol {

    @MainActor private(set) var products: [Product] = []
    @MainActor private(set) var isLoadingProducts: Bool = true

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task(priority: .background) {
            for await verificationResult in Transaction.updates {
                guard case .verified(let transaction) = verificationResult else {
                    AppManager.logger.warning("TipJarManager: unverified transaction update received")
                    continue
                }
                await transaction.finish()
                AppManager.logger.info("TipJarManager: finished transaction from updates listener — \(transaction.productID)")
            }
        }

        Task {
            await finishUnfinishedTransactions()
            await fetchProducts()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func purchase(_ product: Product) async -> TipPurchaseResult {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                guard case .verified(let transaction) = verificationResult else {
                    AppManager.logger.error("TipJarManager: purchase verification failed for \(product.id)")
                    return .failure(StoreKitError.notAvailableInStorefront)
                }
                await transaction.finish()
                let tier = TipTier(rawValue: product.id) ?? .small
                AppManager.logger.info("TipJarManager: purchase successful — \(product.id)")
                return .success(tier)

            case .userCancelled:
                return .userCancelled

            case .pending:
                AppManager.logger.info("TipJarManager: purchase pending — \(product.id)")
                return .pending

            @unknown default:
                return .userCancelled
            }
        } catch {
            AppManager.logger.error("TipJarManager: purchase failed — \(error.localizedDescription)")
            return .failure(error)
        }
    }

    // MARK: - Private -

    private func finishUnfinishedTransactions() async {
        for await verificationResult in Transaction.unfinished {
            guard case .verified(let transaction) = verificationResult else { continue }
            await transaction.finish()
            AppManager.logger.info("TipJarManager: finished unfinished transaction — \(transaction.productID)")
        }
    }

    private func fetchProducts() async {
        do {
            let fetched = try await Product.products(for: TipTier.allCases.map { $0.rawValue })
            let sorted = fetched.sorted { ($0.price as Decimal) < ($1.price as Decimal) }
            await MainActor.run {
                products = sorted
            }
            AppManager.logger.info("TipJarManager: fetched \(fetched.count) products")
        } catch {
            AppManager.logger.error("TipJarManager: failed to fetch products — \(error.localizedDescription)")
        }
        await MainActor.run {
            isLoadingProducts = false
        }
    }
}
