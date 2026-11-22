//
//  HomeSearchModifier.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 22/11/2026.
//

import SwiftUI


//MARK: - Modifier -
struct HomeSearchModifier: ViewModifier {

    @Environment(\.colorScheme)
    private var colorScheme

    @ObservedObject var model: ViewModel
    let title: String

    func body(content: Content) -> some View {
        content
            .accessibilityHidden(self.model.isShowingOverlay)
            .overlay {
                ZStack {
                    if self.model.isShowingOverlay {
                        Color.listBackgroundColor(for: self.colorScheme)
                            .ignoresSafeArea()
                            .transition(.identity)
                        SearchResultsView(model: self.model.results)
                            .transition(HomeSearchMotion.resultsTransition)
                    }
                }
                .motionOrFadeAnimation(HomeSearchMotion.reveal, value: self.model.isShowingOverlay)
            }
            .searchable(text: self.$model.query, isPresented: self.$model.isPresented, prompt: "general_search"~)
            .onSubmit(of: .search) {
                self.model.submit()
            }
            .modifier(SearchFieldSelection(request: self.model.selectionRequest, text: self.model.query))
            .navigationTitle(self.navigationTitle)
    }


    //MARK: - Private -
    private var navigationTitle: String {
        let result: String
        if self.model.isShowingResults {
            result = "general_search"~
        } else {
            result = self.title
        }
        return result
    }
}

extension View {
    func homeSearch(model: HomeSearchModifier.ViewModel, title: String) -> some View {
        return self.modifier(HomeSearchModifier(model: model, title: title))
    }
}


//MARK: - Search Selection -
struct SearchSelectionRequest: Equatable {
    let id: Int
    let start: Int
}

private struct SearchFieldSelection: ViewModifier {
    let request: SearchSelectionRequest
    let text: String

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .modifier(SearchFieldSelectionApplier(request: self.request, text: self.text))
        } else {
            content
        }
    }
}

@available(iOS 26.0, *)
private struct SearchFieldSelectionApplier: ViewModifier {
    let request: SearchSelectionRequest
    let text: String

    @State private var selection: TextSelection?

    func body(content: Content) -> some View {
        content
            .searchSelection(self.fittingSelection)
            .onChange(of: self.request) { _, request in
                let text = self.text
                DispatchQueue.main.async {
                    guard let start = text.index(text.startIndex, offsetBy: request.start, limitedBy: text.endIndex) else { return }
                    self.selection = TextSelection(range: start..<text.endIndex)
                }
            }
    }

    private var fittingSelection: Binding<TextSelection?> {
        return Binding(
            get: {
                guard let selection = self.selection,
                      case .selection(let range) = selection.indices,
                      self.isBoundary(range.lowerBound),
                      self.isBoundary(range.upperBound) else { return nil }
                return selection
            },
            set: { newSelection in
                self.selection = newSelection
            }
        )
    }

    private func isBoundary(_ index: String.Index) -> Bool {
        return index == self.text.endIndex || self.text.indices.contains(index)
    }
}


//MARK: - Motion -
private enum HomeSearchMotion {
    static let reveal = Animation.easeOut(duration: 0.22)
    static let closeAfterDrillDown: TimeInterval = 0.5
    static let typingDebounce: TimeInterval = 0.25
    static let resultsTransition = AnyTransition.asymmetric(insertion: .motion(.opacity.combined(with: .offset(y: 6))),
                                                            removal: .identity)
}


//MARK: - ViewModel -
extension HomeSearchModifier {

    class ViewModel: BaseViewModel, ObservableObject {
        @Published var query: String = "" {
            didSet {
                guard oldValue != self.query, !self.isHoldingResults else { return }
                self.queryChanged()
            }
        }
        @Published var isPresented = false {
            didSet {
                guard oldValue != self.isPresented, self.isPresented else { return }
                self.searchDidOpen()
            }
        }
        @Published private(set) var selectionRequest = SearchSelectionRequest(id: 0, start: 0)
        @Published private(set) var isHoldingResults = false
        private var typedQuery = ""
        private var isSettingQuery = false
        private var pendingResultsUpdate: DispatchWorkItem?
        private let onOpen: (SearchResult) -> Void
        lazy var results = SearchResultsView.ViewModel(appManager: self.appManager,
                                                       onSelect: { [weak self] result in
                                                           self?.open(result)
                                                       },
                                                       onPickRecent: { [weak self] query in
                                                           self?.setQuery(query)
                                                       })

        init(appManager: AppManagerProtocol = AppManager.shared,
             onOpen: @escaping (SearchResult) -> Void) {
            self.onOpen = onOpen
            super.init(appManager: appManager)
        }

        var isShowingResults: Bool {
            let isSearching = !self.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            return isSearching || self.isHoldingResults
        }

        var isShowingOverlay: Bool {
            let isShowingEmptyState = self.isPresented && self.query.isEmpty
            return self.isShowingResults || isShowingEmptyState
        }

        func submit() {
            Log.debug("search submitted, query: \(self.query), results: \(self.results.sections.count)")
            self.appManager.searchManager.recordSearch(self.query)
        }


        //MARK: - Private -
        private func open(_ result: SearchResult) {
            self.pendingResultsUpdate?.cancel()
            self.appManager.searchManager.recordSearch(self.query)
            self.onOpen(result)
            if result.opensScreen {
                self.closeAfterDrillDown()
            } else {
                self.close()
            }
        }

        private func searchDidOpen() {
            self.results.reloadEmptyState()
            guard let lastQuery = self.appManager.searchManager.lastQuery else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self, self.isPresented, self.query.isEmpty else { return }
                Log.debug("search reopened, restored: \(lastQuery)")
                self.setQuery(lastQuery)
                self.requestSelection(from: 0)
            }
        }

        private func queryChanged() {
            let typed = self.query
            let completion = self.isSettingQuery ? nil : self.completionForTyping(typed)
            if let completion {
                Log.debug("search completed from history, typed: \(typed), completion: \(completion)")
                self.setQuery(completion)
                self.typedQuery = typed
                self.requestSelection(from: typed.count)
            } else {
                self.scheduleResultsUpdate(for: typed)
            }
        }

        private func scheduleResultsUpdate(for query: String) {
            self.pendingResultsUpdate?.cancel()
            guard !query.isEmpty else {
                self.results.update(query: query)
                return
            }
            let update = DispatchWorkItem { [weak self] in
                self?.results.update(query: query)
            }
            self.pendingResultsUpdate = update
            DispatchQueue.main.asyncAfter(deadline: .now() + HomeSearchMotion.typingDebounce, execute: update)
        }

        private func completionForTyping(_ typed: String) -> String? {
            let isTypingForward = typed.count > self.typedQuery.count
            self.typedQuery = typed
            guard isTypingForward else { return nil }
            return self.historyCompletion(for: typed)
        }

        private func historyCompletion(for typed: String) -> String? {
            guard !typed.isEmpty else { return nil }
            let recentQueries = self.appManager.searchManager.recentQueries
            guard let match = recentQueries.first(where: { $0.count > typed.count && $0.lowercased().hasPrefix(typed.lowercased()) }) else { return nil }
            return typed + match.dropFirst(typed.count)
        }

        private func setQuery(_ query: String) {
            self.isSettingQuery = true
            self.query = query
            self.isSettingQuery = false
            self.typedQuery = query
        }

        private func requestSelection(from start: Int) {
            self.selectionRequest = SearchSelectionRequest(id: self.selectionRequest.id + 1, start: start)
        }

        private func close() {
            self.setQuery("")
            self.isPresented = false
        }

        private func closeAfterDrillDown() {
            self.isHoldingResults = true
            DispatchQueue.main.asyncAfter(deadline: .now() + HomeSearchMotion.closeAfterDrillDown) { [weak self] in
                guard let self, self.isHoldingResults else { return }
                Log.debug("search closed behind drill-down, query: \(self.results.query)")
                self.isHoldingResults = false
                self.close()
            }
        }
    }
}
