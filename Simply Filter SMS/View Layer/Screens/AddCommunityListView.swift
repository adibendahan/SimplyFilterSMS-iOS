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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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
                        HStack(spacing: 8) {
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
                        .animation(self.reduceMotion ? nil : .bouncy, value: self.model.previewState)
                        .keyframeAnimator(initialValue: CGFloat.zero, trigger: self.shakeTrigger) { content, offset in
                            content.offset(x: offset)
                        } keyframes: { _ in
                            KeyframeTrack {
                                LinearKeyframe(-10, duration: 0.05)
                                LinearKeyframe(10, duration: 0.08)
                                LinearKeyframe(-7, duration: 0.08)
                                LinearKeyframe(7, duration: 0.08)
                                LinearKeyframe(-3, duration: 0.07)
                                LinearKeyframe(0, duration: 0.06)
                            }
                        }
                    } footer: {
                        if case .failed(let error) = self.model.previewState {
                            Label(error.message, systemImage: "exclamationmark.circle")
                                .foregroundColor(.red)
                                .transition(self.reduceMotion ? .identity : .opacity.combined(with: .move(edge: .top)))
                                .accessibilityIdentifier(TestIdentifier.communityListError.rawValue)
                        }
                        else {
                            Text("communityLists_urlHint"~)
                                .transition(self.reduceMotion ? .identity : .opacity)
                        }
                    } // Section
                }

                if self.isPreviewRevealed, case .loaded(let communityList) = self.model.previewState {
                    Section {
                        CommunityListRow(communityList: communityList)
                            .modifier(StaggeredReveal(index: 0))
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
                            .accentColor(Color.primary.opacity(0.35))
                            .modifier(StaggeredReveal(index: index + 1))
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
            .animation(self.reduceMotion ? nil : .easeInOut(duration: 0.25), value: self.model.previewState)
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
                            .foregroundColor(.secondary)
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
                .transition(self.reduceMotion ? .identity : .scale(scale: 0.4).combined(with: .opacity))
        case .loaded:
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.green)
                .transition(self.reduceMotion ? .identity : .scale(scale: 0.3).combined(with: .opacity))
        case .failed:
            Image(systemName: "exclamationmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.red)
                .transition(self.reduceMotion ? .identity : .scale(scale: 0.3).combined(with: .opacity))
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
            if !self.reduceMotion {
                self.shakeTrigger += 1
            }
        case .empty, .loading:
            break
        }
    }

    private func revealPreview() {
        let fieldDelay = self.reduceMotion ? 0 : 0.4
        let countsDelay = self.reduceMotion ? 0 : 0.35 + Double(self.model.filterTypes.count) * StaggeredReveal.step

        DispatchQueue.main.asyncAfter(deadline: .now() + fieldDelay) {
            withAnimation(self.reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.82)) {
                self.isPreviewRevealed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + countsDelay) {
                withAnimation(self.reduceMotion ? nil : .snappy) {
                    self.areCountsShown = true
                }
            }
        }
    }
}

private struct StaggeredReveal: ViewModifier {

    static let step: Double = 0.06

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRevealed = false

    let index: Int

    func body(content: Content) -> some View {
        content
            .opacity(self.isRevealed ? 1 : 0)
            .scaleEffect(self.isRevealed ? 1 : 0.96)
            .offset(y: self.isRevealed ? 0 : 14)
            .onAppear {
                guard !self.isRevealed else { return }
                guard !self.reduceMotion else {
                    self.isRevealed = true
                    return
                }
                withAnimation(.spring(response: 0.45, dampingFraction: 0.8).delay(Double(self.index) * Self.step)) {
                    self.isRevealed = true
                }
            }
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
