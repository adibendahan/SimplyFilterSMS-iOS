//
//  CountryListView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 13/03/2026.
//

import SwiftUI


//MARK: - View -
struct CountryListView: View {

    @StateObject private var model: ViewModel

    @Environment(\.dismiss)
    var dismiss

    init(model: ViewModel = ViewModel()) {
        _model = StateObject(wrappedValue: model)
    }

    var body: some View {
        NavigationView {
        List {
            Section {
                Text(.init("autoFilter_countryAllowlist_explanation"~))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
            }

            let selected = model.selectedEntries
            let unselected = model.unselectedEntries

            if !selected.isEmpty {
                Section(header: Text(String(format: "autoFilter_countryAllowlist_section_allowed"~, selected.count))) {
                    ForEach(selected, id: \.callingCode) { entry in
                        rowView(entry)
                    }
                }
            }

            if !unselected.isEmpty {
                Section(header: Text(String(format: "autoFilter_countryAllowlist_section_blocked"~, unselected.count))) {
                    ForEach(unselected, id: \.callingCode) { entry in
                        rowView(entry)
                    }
                }
            }

            if unselected.isEmpty && selected.isEmpty {
                Section {
                    Text("general_noResults"~)
                        .foregroundColor(.secondary)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("autoFilter_countryAllowlist"~)
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $model.searchQuery, prompt: "general_search"~)
        .animation(.default, value: model.selectedEntries.map(\.callingCode))
        .animation(.default, value: model.unselectedEntries.map(\.callingCode))
        .toolbar {
            ToolbarItem {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("general_close"~)
                .contentShape(Rectangle())
            }
        }
        } // NavigationView
    }

    @ViewBuilder
    private func rowView(_ entry: CallingCodeEntry) -> some View {
        Button {
            model.toggleSelection(entry)
        } label: {
            HStack {
                Text(entry.flagEmoji)
                    .font(.title2)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.displayName)
                        .foregroundColor(.primary)
                    Text(entry.callingCode)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if model.isSelected(entry) {
                    Image(systemName: "checkmark")
                        .foregroundColor(.accentColor)
                        .font(Font.body.bold())
                }
            }
        }
    }
}


//MARK: - ViewModel -
extension CountryListView {

    class ViewModel: BaseViewModel, ObservableObject {
        @Published var searchQuery: String = "" {
            didSet { updateFilteredEntries() }
        }
        @Published private(set) var selectedEntries: [CallingCodeEntry] = []
        @Published private(set) var unselectedEntries: [CallingCodeEntry] = []

        private let rule: RuleType
        private var selectedCodes: Set<String> = []
        private var allEntries: [CallingCodeEntry] = []
        /// Pre-computed localized search terms per calling code (ISO name lookups are expensive).
        private var localizedNames: [String: [String]] = [:]

        init(rule: RuleType = .countryAllowlist,
             appManager: AppManagerProtocol = AppManager.shared) {
            self.rule = rule
            super.init(appManager: appManager)

            self.allEntries = CallingCodeEntry.allCases
                .sorted { Self.sortIndex($0) < Self.sortIndex($1) }

            // Pre-compute localized country names for each entry.
            for entry in self.allEntries {
                let names = entry.isoCountryCodes.compactMap {
                    Locale.current.localizedString(forRegionCode: $0)
                }
                localizedNames[entry.callingCode] = names
            }

            let stored = appManager.automaticFilterManager.selectedCountries(for: rule)
            self.selectedCodes = Set(stored)

            updateFilteredEntries()
        }

        func isSelected(_ entry: CallingCodeEntry) -> Bool {
            selectedCodes.contains(entry.callingCode)
        }

        func toggleSelection(_ entry: CallingCodeEntry) {
            if selectedCodes.contains(entry.callingCode) {
                selectedCodes.remove(entry.callingCode)
            } else {
                selectedCodes.insert(entry.callingCode)
            }
            appManager.automaticFilterManager.setSelectedCountries(Array(selectedCodes), for: rule)
            withAnimation {
                updateFilteredEntries()
            }
        }

        /// Summary string for the disclosure row shown in the parent list.
        func selectionSummary() -> String {
            guard !selectedCodes.isEmpty else { return "autoFilter_countryAllowlist_empty"~ }
            // allEntries is already sorted with US/Israel first, so just filter in place.
            let names = allEntries
                .filter { selectedCodes.contains($0.callingCode) }
                .map { $0.summaryName }
            guard let first = names.first else { return "autoFilter_countryAllowlist_empty"~ }
            if names.count == 1 { return first }
            return "\(first) + \(names.count - 1) \("general_more"~)"
        }

        // MARK: - Private

        /// Sort: +1 (US/NANP) first, +972 (Israel) second, rest by numeric code.
        private static func sortIndex(_ entry: CallingCodeEntry) -> Int {
            switch entry.callingCode {
            case "+1":
                return -2
            case "+972":
                return -1
            default:
                return Int(entry.callingCode.dropFirst()) ?? Int.max
            }
        }

        private func updateFilteredEntries() {
            let query = searchQuery.trimmingCharacters(in: .whitespaces)
            let matches: [CallingCodeEntry]
            if query.isEmpty {
                matches = allEntries
            } else {
                matches = allEntries.filter { entry in
                    entry.displayName.localizedCaseInsensitiveContains(query) ||
                    entry.callingCode.contains(query) ||
                    entry.isoCountryCodes.contains { $0.caseInsensitiveCompare(query) == .orderedSame } ||
                    (localizedNames[entry.callingCode] ?? []).contains { $0.localizedCaseInsensitiveContains(query) }
                }
            }
            selectedEntries = matches.filter { selectedCodes.contains($0.callingCode) }
            unselectedEntries = matches.filter { !selectedCodes.contains($0.callingCode) }
        }
    }
}


//MARK: - Preview -
struct CountryListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CountryListView(model: CountryListView.ViewModel(appManager: AppManager.previews))
        }
    }
}
