//
//  TipJarManager.swift
//  Simply Filter SMS
//

import StoreKit

class TipJarManager: TipJarManagerProtocol {

    @MainActor private(set) var products: [Product] = []
    @MainActor private(set) var isLoadingProducts: Bool = true

    private var defaultsManager: DefaultsManagerProtocol
    private var updatesTask: Task<Void, Never>?

    init(defaultsManager: DefaultsManagerProtocol = AppManager.shared.defaultsManager) {
        self.defaultsManager = defaultsManager
        updatesTask = Task(priority: .background) {
            for await verificationResult in Transaction.updates {
                guard case .verified(let transaction) = verificationResult else {
                    Log.debug("unverified transaction update, product: \(verificationResult.unsafePayloadValue.productID) → skipped")
                    continue
                }
                await transaction.finish()
                Log.debug("transaction finished, source: 'updates', product: \(transaction.productID)")
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
        Log.debug("purchase started, product: \(product.id)")
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                guard case .verified(let transaction) = verificationResult else {
                    Log.error("purchase verification failed, product: \(product.id)")
                    return .failure(StoreKitError.notAvailableInStorefront)
                }
                await transaction.finish()
                self.defaultsManager.didTip = true
                let tier = TipTier(rawValue: product.id) ?? .small
                Log.debug("purchase succeeded, product: \(product.id)")
                return .success(tier)
            case .userCancelled:
                Log.debug("purchase cancelled, product: \(product.id)")
                return .userCancelled
            case .pending:
                Log.debug("purchase pending, product: \(product.id)")
                return .pending
            @unknown default:
                Log.debug("unknown purchase result, product: \(product.id) → treated as cancelled")
                return .userCancelled
            }
        } catch {
            Log.error("purchase failed, product: \(product.id)", error: error)
            return .failure(error)
        }
    }

    // MARK: - Private -

    private func finishUnfinishedTransactions() async {
        for await verificationResult in Transaction.unfinished {
            guard case .verified(let transaction) = verificationResult else {
                Log.debug("unverified unfinished transaction, product: \(verificationResult.unsafePayloadValue.productID) → skipped")
                continue
            }
            await transaction.finish()
            Log.debug("transaction finished, source: 'unfinished', product: \(transaction.productID)")
        }
    }

    private func fetchProducts() async {
        do {
            let fetched = try await Product.products(for: TipTier.allCases.map { $0.rawValue })
            let sorted = fetched.sorted { ($0.price as Decimal) < ($1.price as Decimal) }
            await MainActor.run {
                products = sorted
            }
            Log.debug("products fetched, products: \(sorted.map(\.id))")
        } catch {
            Log.error("products fetch failed", error: error)
        }
        await MainActor.run {
            isLoadingProducts = false
        }
    }
}
