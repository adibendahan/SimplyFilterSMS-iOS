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

    @ScaledMetric(relativeTo: .largeTitle) private var heartSizeRegular: CGFloat = 64
    @ScaledMetric(relativeTo: .title2) private var heartSizeCompact: CGFloat = 32
    @ScaledMetric(relativeTo: .title) private var signatureHeight: CGFloat = 27

    @StateObject var model: ViewModel

    @State private var hasAppeared = false

    init(model: ViewModel) {
        _model = StateObject(wrappedValue: model)
    }

    private var isCompact: Bool {
        return self.verticalSizeClass == .compact
    }

    private var isTipContentRevealed: Bool {
        return self.hasAppeared && !self.model.isLoading
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 0) {
                        self.headerSection
                        Spacer(minLength: self.isCompact ? 12 : 24)
                        self.tipSection
                        self.footerSection
                    }
                    .padding(.horizontal, 20)
                    .frame(minHeight: geometry.size.height)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        self.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.primary)
                    }
                    .tint(.primary)
                    .accessibilityLabel("general_close"~)
                    .contentShape(Rectangle())
                }
            }
            .onChange(of: self.model.shouldDismiss) { _, shouldDismiss in
                if shouldDismiss { self.dismiss() }
            }
            .onAppear {
                self.hasAppeared = true
            }
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 0) {
            Image(systemName: "heart.fill")
                .font(.system(size: self.isCompact ? self.heartSizeCompact : self.heartSizeRegular))
                .foregroundStyle(.red)
                .accessibilityHidden(true)
                .breathe()
                .bounceOnAppear(isShown: self.hasAppeared, delay: TipJarMotion.heartBounceDelay)
                .strokeRippleOnTap(systemName: "heart", color: .red)
                .padding(.vertical, self.isCompact ? 4 : 20)
                .entrance(isShown: self.hasAppeared, delay: TipJarMotion.heartDelay, rise: 0, scale: TipJarMotion.heartStartScale, blur: TipJarMotion.heartBlur, animation: TipJarMotion.heartAnimation)

            VStack(spacing: 0) {
                Text("tipJar_header"~)
                    .font(self.isCompact ? .headline : .title2.bold())
                    .multilineTextAlignment(.center)

                Text("tipJar_subheader"~)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            }
            .settle(isShown: self.hasAppeared, delay: TipJarMotion.textDelay)

            Image("TipJarSignature")
                .resizable()
                .scaledToFit()
                .frame(height: self.signatureHeight)
                .foregroundStyle(.tint)
                .writeOn(isShown: self.hasAppeared, delay: TipJarMotion.signatureDelay, duration: TipJarMotion.signatureDuration)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.horizontal, 20)
                .accessibilityHidden(true)
        }
    }

    @ViewBuilder
    private var tipSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("tipJar_chooseATip"~)
                .font(.footnote)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .padding(.leading, 4)
                .settle(isShown: self.hasAppeared, delay: TipJarMotion.pickerDelay)

            if !self.model.isLoading && self.model.options.isEmpty {
                Text("tipJar_unavailable"~)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .transition(.opacity)
            } else {
                TipTierPicker(options: self.model.options, selection: self.$model.selectedTier, isCompact: self.isCompact, isRevealed: self.isTipContentRevealed)
                    .disabled(self.model.isPurchasing || self.model.isLoading)
                    .overlay {
                        if self.model.isLoading {
                            ProgressView()
                                .transition(.opacity)
                        }
                    }
                    .motionAnimation(ReducedMotion.fade, value: self.model.isLoading)
                    .settle(isShown: self.hasAppeared, delay: TipJarMotion.pickerDelay)

                self.tierCaption
                    .padding(.top, 4)
                    .settle(isShown: self.isTipContentRevealed, delay: TipJarMotion.captionDelay)

                self.tipButton
                    .padding(.top, 8)
                    .settle(isShown: self.isTipContentRevealed, delay: TipJarMotion.buttonDelay)
            }
        }
    }

    private var tierCaption: some View {
        let tier = self.model.selectedTier
        return ZStack {
            Text("\(tier.displayName) · \(tier.tierDescription)")
                .font(self.isCompact ? .footnote : .subheadline)
                .foregroundColor(.secondary)
                .adaptiveLineLimit(1)
                .minimumScaleFactor(0.8)
                .id(tier)
                .transition(.motion(.push(from: .bottom)))
        }
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var tipButton: some View {
        Button {
            Task { await self.model.purchaseSelectedTier() }
        } label: {
            Text(String(format: "tipJar_tipButton"~, self.model.selectedDisplayPrice))
                .contentTransition(.numericText())
                .spinnerSwap(isActive: self.model.isPurchasing, tint: .white)
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(FilledButton())
        .buttonBorderShape(.capsule)
    }

    @ViewBuilder
    private var footerSection: some View {
        Text("tipJar_footer"~)
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .limitedDynamicTypeSize()
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
            .padding(.bottom, 16)
            .settle(isShown: self.isTipContentRevealed, delay: TipJarMotion.footerDelay)
    }
}


//MARK: - Motion -
private enum TipJarMotion {
    static let heartDelay: Double = 0.1
    static let heartStartScale: CGFloat = 0.5
    static let heartBlur: CGFloat = 8
    static let heartAnimation = Animation.spring(response: 0.55, dampingFraction: 0.7)
    static let heartBounceDelay: Double = 0.45
    static let textDelay: Double = 0.2
    static let signatureDelay: Double = 0.55
    static let signatureDuration: Double = 0.7
    static let pickerDelay: Double = 0.3
    static let captionDelay: Double = 0.35
    static let buttonDelay: Double = 0.4
    static let footerDelay: Double = 0.45
    static let rise: CGFloat = 10
    static let blur: CGFloat = 6
    static let settleAnimation = Animation.spring(response: 0.6, dampingFraction: 0.85)
}

private extension View {
    func settle(isShown: Bool, delay: Double) -> some View {
        return self.entrance(isShown: isShown, delay: delay, rise: TipJarMotion.rise, blur: TipJarMotion.blur, animation: TipJarMotion.settleAnimation)
    }
}


//MARK: - ViewModel -
extension TipJarView {

    class ViewModel: BaseViewModel, ObservableObject {
        @Published var products: [Product] = []
        @Published var isLoading: Bool = true
        @Published var purchaseState: PurchaseState = .idle
        @Published var shouldDismiss: Bool = false
        @Published var selectedTier: TipTier = .medium {
            didSet {
                guard oldValue != self.selectedTier else { return }
                Log.debug("tip tier selected, tier: \(oldValue) → \(self.selectedTier)")
            }
        }

        enum PurchaseState: Equatable {
            case idle
            case purchasing(TipTier)
            case success(TipTier)
            case error
        }

        var isPurchasing: Bool {
            if case .purchasing = self.purchaseState { return true }
            return false
        }

        var options: [TipTierPicker.Option] {
            let result: [TipTierPicker.Option]
            if self.isLoading {
                result = self.placeholderOptions
            } else {
                result = self.productOptions
            }
            return result
        }

        var selectedDisplayPrice: String {
            let option = self.options.first { $0.tier == self.selectedTier }
            return option?.displayPrice ?? self.selectedTier.fallbackPrice
        }

        override init(appManager: AppManagerProtocol = AppManager.shared) {
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
                self.selectAvailableTier()
            }
        }

        @MainActor
        func purchaseSelectedTier() async {
            guard !self.isPurchasing else { return }
            let tier = self.selectedTier
            guard let product = self.products.first(where: { $0.id == tier.rawValue }) else {
                Log.fault("selected tier has no product, tier: \(tier) → not purchased")
                self.purchaseState = .error
                return
            }
            await self.purchase(product)
        }


        //MARK: - Private -
        private var placeholderOptions: [TipTierPicker.Option] {
            var result: [TipTierPicker.Option] = []
            for tier in TipTier.allCases {
                result.append(TipTierPicker.Option(tier: tier, displayPrice: tier.fallbackPrice))
            }
            return result
        }

        private var productOptions: [TipTierPicker.Option] {
            var result: [TipTierPicker.Option] = []
            for product in self.products {
                guard let tier = TipTier(rawValue: product.id) else { continue }
                result.append(TipTierPicker.Option(tier: tier, displayPrice: product.displayPrice))
            }
            return result
        }

        @MainActor
        private func selectAvailableTier() {
            let availableTiers = self.options.map { $0.tier }
            guard let firstTier = availableTiers.first, !availableTiers.contains(self.selectedTier) else { return }
            Log.debug("selected tier unavailable, tier: \(self.selectedTier), available: \(availableTiers) → \(firstTier)")
            self.selectedTier = firstTier
        }

        @MainActor
        private func purchase(_ product: Product) async {
            guard let tier = TipTier(rawValue: product.id) else {
                Log.fault("product has no tip tier, product: \(product.id) → error shown")
                self.purchaseState = .error
                return
            }
            self.purchaseState = .purchasing(tier)

            let result = await self.appManager.tipJarManager.purchase(product)

            switch result {
            case .success(let tier):
                self.purchaseState = .success(tier)
                self.appManager.flowManager.requestToast(.tipSuccessful(tier))
                self.shouldDismiss = true

            case .userCancelled, .pending:
                self.purchaseState = .idle

            case .failure:
                self.purchaseState = .error
                Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    if case .error = self?.purchaseState {
                        self?.purchaseState = .idle
                    }
                }
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
