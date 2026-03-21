//
//  TipJarManager.swift
//  Simply Filter SMS
//

import StoreKit
import OSLog

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
                    AppManager.logger.debug("TipJarManager — unverified transaction update received")
                    continue
                }
                await transaction.finish()
                AppManager.logger.debug("TipJarManager — finished transaction from updates listener: \(transaction.productID, privacy: .public)")
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
        AppManager.logger.debug("TipJarManager — purchase started: \(product.id, privacy: .public)")
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verificationResult):
                guard case .verified(let transaction) = verificationResult else {
                    AppManager.logger.error("TipJarManager — purchase verification failed: \(product.id, privacy: .public)")
                    return .failure(StoreKitError.notAvailableInStorefront)
                }
                await transaction.finish()
                self.defaultsManager.didTip = true
                let tier = TipTier(rawValue: product.id) ?? .small
                AppManager.logger.debug("TipJarManager — purchase successful: \(product.id, privacy: .public)")
                return .success(tier)
            case .userCancelled:
                AppManager.logger.debug("TipJarManager — purchase cancelled: \(product.id, privacy: .public)")
                return .userCancelled
            case .pending:
                AppManager.logger.debug("TipJarManager — purchase pending: \(product.id, privacy: .public)")
                return .pending
            @unknown default:
                return .userCancelled
            }
        } catch {
            AppManager.logger.error("TipJarManager — purchase error: \(error.localizedDescription, privacy: .public)")
            return .failure(error)
        }
    }

    // MARK: - Private -

    private func finishUnfinishedTransactions() async {
        for await verificationResult in Transaction.unfinished {
            guard case .verified(let transaction) = verificationResult else { continue }
            await transaction.finish()
            AppManager.logger.debug("TipJarManager — finished unfinished transaction: \(transaction.productID, privacy: .public)")
        }
    }

    private func fetchProducts() async {
        do {
            let fetched = try await Product.products(for: TipTier.allCases.map { $0.rawValue })
            let sorted = fetched.sorted { ($0.price as Decimal) < ($1.price as Decimal) }
            await MainActor.run {
                products = sorted
            }
            AppManager.logger.debug("TipJarManager — fetched \(fetched.count, privacy: .public) products")
        } catch {
            AppManager.logger.error("TipJarManager — failed to fetch products: \(error.localizedDescription, privacy: .public)")
        }
        await MainActor.run {
            isLoadingProducts = false
        }
    }
}
