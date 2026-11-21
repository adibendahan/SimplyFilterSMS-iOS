//
//  SearchResultsView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 21/11/2026.
//

import SwiftUI


//MARK: - View -
struct SearchResultsView: View {

    @ObservedObject var model: ViewModel

    var body: some View {
        List {
            if self.model.isShowingSuggestions {
                Section {
                    ForEach(self.model.suggestionRows) { row in
                        self.rowView(for: row)
                    }
                } header: {
                    Text("search_suggestions"~)
                        .accessibilityAddTraits(.isHeader)
                } // Section
            }

            if self.model.isShowingRecents {
                Section {
                    ForEach(self.model.recentQueries, id: \.self) { query in
                        Button {
                            self.model.pickRecent(query)
                        } label: {
                            AdaptiveRow {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundStyle(.secondary)
                                    .adaptiveIconColumn()
                                    .accessibilityHidden(true)
                            } content: {
                                Text(query)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    HStack {
                        Text("search_recent"~)
                            .accessibilityAddTraits(.isHeader)
                        Spacer()
                        Button("search_clearRecent"~) {
                            self.model.clearRecents()
                        }
                        .textCase(nil)
                    }
                } // Section
            }

            ForEach(self.model.sections) { section in
                Section {
                    ForEach(section.rows) { row in
                        self.rowView(for: row)
                    }
                } header: {
                    Text(section.kind.title)
                        .accessibilityAddTraits(.isHeader)
                } // Section
            }
        } // List
        .listStyle(.insetGrouped)
        .sensoryFeedback(.selection, trigger: self.model.selectedRowID) { _, selectedRowID in
            return selectedRowID != nil
        }
        .overlay {
            if self.model.hasNoResults {
                ContentUnavailableView.search(text: self.model.query)
            }
        }
    }


    //MARK: - Private -
    private func rowView(for row: SearchResultRowView.Row) -> some View {
        return SearchResultRowView(row: row, query: self.model.query, isSelected: self.model.selectedRowID == row.id) {
            self.model.select(row)
        }
    }
}


private enum SearchResultsMotion {
    static let update = Animation.smooth(duration: 0.3)
    static let selectionHold: Double = 1.0
}


//MARK: - Sections -
extension SearchResultsView {
    struct ResultSection: Identifiable {
        let kind: SearchResultKind
        let rows: [SearchResultRowView.Row]

        var id: SearchResultKind {
            return self.kind
        }
    }
}


//MARK: - ViewModel -
extension SearchResultsView {

    class ViewModel: BaseViewModel, ObservableObject {
        @Published private(set) var query: String = ""
        @Published private(set) var sections: [ResultSection] = []
        @Published private(set) var recentQueries: [String] = []
        @Published private(set) var suggestionRows: [SearchResultRowView.Row] = []
        @Published private(set) var selectedRowID: String?
        private let onSelect: (SearchResult) -> Void
        private let onPickRecent: (String) -> Void

        init(appManager: AppManagerProtocol = AppManager.shared,
             onSelect: @escaping (SearchResult) -> Void,
             onPickRecent: @escaping (String) -> Void) {
            self.onSelect = onSelect
            self.onPickRecent = onPickRecent
            super.init(appManager: appManager)
        }

        var isShowingRecents: Bool {
            return self.query.isEmpty && !self.recentQueries.isEmpty
        }

        var isShowingSuggestions: Bool {
            return self.query.isEmpty && !self.suggestionRows.isEmpty
        }

        func reloadEmptyState() {
            let searchManager = self.appManager.searchManager
            self.recentQueries = searchManager.recentQueries
            self.suggestionRows = searchManager.suggestions.map { self.makeRow($0, kind: $0.kind) }
        }

        func pickRecent(_ query: String) {
            Log.debug("recent search picked, query: \(query)")
            self.onPickRecent(query)
        }

        func clearRecents() {
            self.appManager.searchManager.clearRecentQueries()
            self.recentQueries = []
        }

        var hasNoResults: Bool {
            let term = self.query.trimmingCharacters(in: .whitespacesAndNewlines)
            return !term.isEmpty && self.sections.isEmpty
        }

        func update(query: String) {
            let resultSections = self.appManager.searchManager.sections(matching: query)
            let sections = resultSections.map { resultSection in
                let rows = resultSection.results.map { self.makeRow($0, kind: resultSection.kind) }
                return ResultSection(kind: resultSection.kind, rows: rows)
            }
            let sectionKinds = sections.map(\.kind)
            let currentSectionKinds = self.sections.map(\.kind)
            let keepsSections = !query.isEmpty && sectionKinds == currentSectionKinds
            let animation = keepsSections ? SearchResultsMotion.update : nil
            withMotionAnimation(animation) {
                self.query = query
                self.sections = sections
            }
        }

        func select(_ row: SearchResultRowView.Row) {
            Log.debug("result selected, kind: \(row.kind), title: \(row.title)")
            let rowID = row.id
            self.selectedRowID = rowID
            DispatchQueue.main.asyncAfter(deadline: .now() + SearchResultsMotion.selectionHold) { [weak self] in
                if self?.selectedRowID == rowID {
                    self?.selectedRowID = nil
                }
            }
            self.onSelect(row.result)
        }


        //MARK: - Private -
        private func makeRow(_ result: SearchResult, kind: SearchResultKind) -> SearchResultRowView.Row {
            return SearchResultRowView.Row(result: result, kind: kind, appManager: self.appManager)
        }
    }
}
