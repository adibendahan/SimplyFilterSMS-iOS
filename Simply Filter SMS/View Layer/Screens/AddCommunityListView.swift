//
//  AddCommunityListView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 12/11/2026.
//

import SwiftUI


//MARK: - View -
struct AddCommunityListView: View {

    @Environment(\.dismiss) var dismiss

    @ObservedObject var model: ViewModel
    @FocusState private var isURLFieldFocused: Bool
    @State private var isPreviewRevealed = false
    @State private var areCountsShown = false
    @State private var shakeTrigger = 0

    var body: some View {
        NavigationView {
            List {
                if !self.isPreviewRevealed {
                    Section {
                        HStack(spacing: Spacing.item) {
                            TextField("https://", text: $model.urlText)
                                .accessibilityLabel("a11y_communityLists_urlField"~)
                                .keyboardType(.URL)
                                .textContentType(.URL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.done)
                                .focused($isURLFieldFocused)
                                .accessibilityIdentifier(TestIdentifier.communityListURLField.rawValue)

                            self.urlFieldStatus
                        }
                        .motionAnimation(.bouncy, value: self.model.previewState)
                        .shake(trigger: self.shakeTrigger)
                    } footer: {
                        if case .failed(let error) = self.model.previewState {
                            Label(error.message, systemImage: "exclamationmark.circle")
                                .foregroundColor(.red)
                                .transition(.motion(.opacity.combined(with: .move(edge: .top))))
                                .accessibilityIdentifier(TestIdentifier.communityListError.rawValue)
                        }
                        else {
                            Text("communityLists_urlHint"~)
                                .transition(.opacity)
                        }
                    } // Section
                }

                if self.isPreviewRevealed, case .loaded(let communityList) = self.model.previewState {
                    Section {
                        CommunityListRow(communityList: communityList)
                            .previewReveal(index: 0)
                    } header: {
                        Text("communityLists_preview"~)
                    }

                    Section {
                        ForEach(Array(self.model.filterTypes.enumerated()), id: \.element) { index, filterType in
                            NavigationLink {
                                FilterTransferCandidateListView(filterType: filterType,
                                                                candidates: self.model.candidates(for: filterType))
                            } label: {
                                FilterTransferTypeRow(filterType: filterType,
                                                      count: self.areCountsShown ? self.model.candidates(for: filterType).count : 0)
                            }
                            .accentColor(Color(.tertiaryLabel))
                            .previewReveal(index: index + 1)
                        }
                    } header: {
                        Text("filterList_filters"~)
                    } footer: {
                        Text(self.model.didFailToSubscribe ? "communityLists_error_subscribeFailed"~ : "communityLists_trustNote"~)
                            .foregroundColor(self.model.didFailToSubscribe ? .red : .secondary)
                    }
                }
            } // List
            .listStyle(.insetGrouped)
            .motionAnimation(.easeInOut(duration: 0.25), value: self.model.previewState)
            .onChange(of: self.model.previewState) { oldState, newState in
                self.previewStateChanged(from: oldState, to: newState)
            }
            .navigationTitle("communityLists_subscribeFromURL"~)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.textSecondary)
                    }
                    .tint(.primary)
                    .accessibilityLabel("general_close"~)
                    .contentShape(Rectangle())
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("communityLists_subscribe"~) {
                        Task {
                            let isSubscribed = await self.model.subscribe()
                            if isSubscribed {
                                dismiss()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!self.model.canSubscribe)
                    .accessibilityIdentifier(TestIdentifier.subscribeCommunityListButton.rawValue)
                }
            }
        } // NavigationView
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                self.isURLFieldFocused = true
            }
        }
    }

    @ViewBuilder
    private var urlFieldStatus: some View {
        switch self.model.previewState {
        case .loading:
            ProgressView()
                .transition(.motion(.scale(scale: 0.4).combined(with: .opacity)))
        case .loaded:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)
                .transition(.motion(.scale(scale: 0.3).combined(with: .opacity)))
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.red)
                .transition(.motion(.scale(scale: 0.3).combined(with: .opacity)))
        case .empty:
            EmptyView()
        }
    }

    private func previewStateChanged(from oldState: PreviewState, to newState: PreviewState) {
        guard oldState == .loading else { return }

        switch newState {
        case .loaded:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            self.revealPreview()
        case .failed:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            self.shakeTrigger += 1
        case .empty, .loading:
            break
        }
    }

    private func revealPreview() {
        let countsDelay = PreviewMotion.countsBaseDelay + Stagger.delay(for: self.model.filterTypes.count, step: PreviewMotion.step)

        DispatchQueue.main.asyncAfter(deadline: .now() + PreviewMotion.fieldDelay) {
            withMotionAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                self.isPreviewRevealed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + countsDelay) {
                withMotionAnimation(.snappy) {
                    self.areCountsShown = true
                }
            }
        }
    }
}

//MARK: - Motion -
private enum PreviewMotion {
    static let step: Double = 0.06
    static let fieldDelay: Double = 0.4
    static let countsBaseDelay: Double = 0.35
    static let rise: CGFloat = 14
    static let startScale: CGFloat = 0.96
    static let animation = Animation.spring(response: 0.45, dampingFraction: 0.8)
}

private extension View {
    func previewReveal(index: Int) -> some View {
        return self.entranceOnAppear(delay: Stagger.delay(for: index, step: PreviewMotion.step), rise: PreviewMotion.rise, scale: PreviewMotion.startScale, animation: PreviewMotion.animation)
    }
}


//MARK: - ViewModel -
extension AddCommunityListView {

    enum PreviewState: Equatable {
        case empty, loading, loaded(CommunityListItem), failed(CommunityListPreviewError)
    }

    class ViewModel: BaseViewModel, ObservableObject, Identifiable {
        let id = UUID()
        @Published var urlText = "" {
            didSet {
                guard oldValue != self.urlText else { return }
                self.schedulePreview()
            }
        }
        @Published private(set) var previewState: PreviewState = .empty {
            didSet {
                guard oldValue != self.previewState else { return }
                Log.debug("community list preview, state: \(oldValue.logName) → \(self.previewState.logName)")
            }
        }
        @Published private(set) var filterCandidates: [FilterTransferCandidate] = []
        @Published private(set) var isSubscribing = false
        @Published private(set) var didFailToSubscribe = false

        private let previewDelay: Duration
        private var previewTask: Task<Void, Never>?

        var isLoaded: Bool {
            guard case .loaded = self.previewState else { return false }
            return true
        }

        var canSubscribe: Bool {
            return self.isLoaded && !self.isSubscribing
        }

        var filterTypes: [FilterType] {
            return FilterType.allCases
                .sorted(by: { $0.sortIndex < $1.sortIndex })
                .filter({ !self.candidates(for: $0).isEmpty })
        }

        func candidates(for type: FilterType) -> [FilterTransferCandidate] {
            return self.filterCandidates.filter({ $0.type == type })
        }

        init(previewDelay: Duration = .milliseconds(600),
             appManager: AppManagerProtocol = AppManager.shared) {
            self.previewDelay = previewDelay
            super.init(appManager: appManager)
        }

        @MainActor
        func subscribe() async -> Bool {
            guard case .loaded(let communityList) = self.previewState, !self.isSubscribing else {
                Log.debug("nothing to subscribe, state: \(self.previewState.logName), subscribing: \(self.isSubscribing) → skipped")
                return false
            }
            self.isSubscribing = true
            let isSubscribed = await self.appManager.filterListManager.subscribeCommunityList(communityList)
            self.isSubscribing = false
            self.didFailToSubscribe = !isSubscribed
            Log.debug("subscribe tapped, url: \(communityList.url) → \(isSubscribed)")
            if isSubscribed {
                self.appManager.flowManager.offerStayReachable()
            }
            return isSubscribed
        }

        private func schedulePreview() {
            self.previewTask?.cancel()
            self.didFailToSubscribe = false
            self.filterCandidates = []
            self.previewState = .empty

            let trimmedText = self.urlText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedText.isEmpty else { return }
            guard let url = URL(string: trimmedText) else {
                self.previewState = .failed(.invalidURL)
                return
            }

            let previewDelay = self.previewDelay
            self.previewTask = Task { @MainActor [weak self] in
                try? await Task.sleep(for: previewDelay)
                guard !Task.isCancelled, let self else { return }
                self.previewState = .loading
                let previewResult = await self.appManager.filterListManager.previewCommunityList(at: url)
                guard !Task.isCancelled else { return }

                switch previewResult {
                case .success(let communityList):
                    let records = communityList.cacheSection?.payload.filters ?? []
                    self.filterCandidates = records.compactMap({ FilterTransferCandidate(record: $0) })
                    self.previewState = .loaded(communityList)
                case .failure(let error):
                    self.previewState = .failed(error)
                }
            }
        }
    }
}

extension AddCommunityListView.PreviewState {
    var logName: String {
        switch self {
        case .empty:
            return "empty"
        case .loading:
            return "loading"
        case .loaded:
            return "loaded"
        case .failed(let error):
            return "failed: \(error)"
        }
    }
}


//MARK: - Preview -
struct AddCommunityListView_Previews: PreviewProvider {
    static var previews: some View {
        AddCommunityListView(model: AddCommunityListView.ViewModel(appManager: AppManager.previews))
    }
}
