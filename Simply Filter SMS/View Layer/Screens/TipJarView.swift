//
//  TipJarView.swift
//  Simply Filter SMS
//

import SwiftUI
import StoreKit


//MARK: - View -
struct TipJarView: View {

    @Environment(\.dismiss)
    var dismiss

    @Environment(\.verticalSizeClass)
    var verticalSizeClass

    @ScaledMetric(relativeTo: .largeTitle) private var heartSizeRegular: CGFloat = 56
    @ScaledMetric(relativeTo: .title2) private var heartSizeCompact: CGFloat = 32

    @ObservedObject var model: ViewModel

    private var isCompact: Bool { verticalSizeClass == .compact }

    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack(spacing: isCompact ? 8 : 16) {
                        headerSection
                        tipCardsSection
                        footerSection
                    }
                    .padding(.horizontal)
                }

                confettiOverlay
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("general_close"~)
                    .contentShape(Rectangle())
                }
            }
            .onChange(of: model.shouldDismiss) { shouldDismiss in
                if shouldDismiss { dismiss() }
            }
        }
        .modifier(EmbeddedNotificationView(model: model.notification))
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: isCompact ? 4 : 12) {
            Text("❤️")
                .font(.system(size: isCompact ? heartSizeCompact : heartSizeRegular))
                .accessibilityHidden(true)

            Text("tipJar_header"~)
                .font(isCompact ? .headline : .title2.bold())
                .multilineTextAlignment(.center)

            Text("tipJar_subheader"~)
                .font(isCompact ? .caption : .body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, isCompact ? 8 : 16)
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private var tipCardsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("tipJar_chooseATip"~)
                .font(.footnote)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)

            if model.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.vertical, 20)
            } else if model.products.isEmpty {
                Text("tipJar_unavailable"~)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 20)
            } else {
                HStack(spacing: 10) {
                    ForEach(model.products, id: \.id) { product in
                        if let tier = TipTier(rawValue: product.id) {
                            TipCardView(tier: tier, displayPrice: product.displayPrice, isDisabled: model.isPurchasing, isPurchasing: model.isPurchasing(tier: tier), isCompact: isCompact) {
                                Task { await model.purchase(product) }
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
    }

    @ViewBuilder
    private var footerSection: some View {
        Text("tipJar_footer"~)
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 16)
    }

    @ViewBuilder
    private var confettiOverlay: some View {
        if case .success(let tier) = model.purchaseState {
            ConfettiView(
                birthRate: tier.confettiBirthRate,
                lifetime: tier.confettiLifetime,
                velocity: tier.confettiVelocity
            )
            .ignoresSafeArea()
            .allowsHitTesting(false)
        }
    }
}


//MARK: - ViewModel -
extension TipJarView {

    class ViewModel: BaseViewModel, ObservableObject {
        @Published var products: [Product] = []
        @Published var isLoading: Bool = true
        @Published var purchaseState: PurchaseState = .idle
        @Published var notification: NotificationView.ViewModel
        @Published var shouldDismiss: Bool = false

        enum PurchaseState: Equatable {
            case idle
            case purchasing(TipTier)
            case success(TipTier)
            case error
        }

        var isPurchasing: Bool {
            if case .purchasing = purchaseState { return true }
            return false
        }

        func isPurchasing(tier: TipTier) -> Bool {
            if case .purchasing(let t) = purchaseState { return t == tier }
            return false
        }

        override init(appManager: AppManagerProtocol = AppManager.shared) {
            self.notification = NotificationView.ViewModel(notification: .tipSuccessful)
            super.init(appManager: appManager)

            Task { @MainActor [weak self] in
                guard let self else { return }
                let manager = self.appManager.tipJarManager
                self.products = manager.products
                self.isLoading = manager.isLoadingProducts

                if manager.isLoadingProducts {
                    while self.appManager.tipJarManager.isLoadingProducts {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                    }
                    self.products = self.appManager.tipJarManager.products
                    self.isLoading = false
                }
            }
        }

        @MainActor
        func purchase(_ product: Product) async {
            guard let tier = TipTier(rawValue: product.id) else {
                purchaseState = .error
                return
            }
            purchaseState = .purchasing(tier)

            let result = await appManager.tipJarManager.purchase(product)

            switch result {
            case .success(let tier):
                purchaseState = .success(tier)
                showThankYouToast()

                let delay = Double(tier.confettiLifetime) + 0.5
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    if case .success = self?.purchaseState {
                        self?.purchaseState = .idle
                    }
                }

            case .userCancelled, .pending:
                purchaseState = .idle

            case .failure:
                purchaseState = .error
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    if case .error = self?.purchaseState {
                        self?.purchaseState = .idle
                    }
                }
            }
        }

        private func showThankYouToast() {
            notification.setNotification(.tipSuccessful)
            notification.onHide = { [weak self] in
                self?.shouldDismiss = true
            }
            withAnimation {
                notification.show = true
            }
        }
    }
}


//MARK: - Preview -
struct TipJarView_Previews: PreviewProvider {
    static var previews: some View {
        TipJarView(model: TipJarView.ViewModel(appManager: AppManager.previews))
    }
}
