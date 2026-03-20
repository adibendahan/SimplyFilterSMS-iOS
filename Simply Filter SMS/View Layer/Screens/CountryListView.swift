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
                .accessibilityIdentifier(TestIdentifier.closeButton.rawValue)
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
        .accessibilityIdentifier(TestIdentifier.countryRow.rawValue)
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
        /// ISO region codes whose primary (or a major) language matches the current locale's language.
        private var localeLanguageRegions: Set<String> = []

        init(rule: RuleType = .countryAllowlist,
             appManager: AppManagerProtocol = AppManager.shared) {
            self.rule = rule
            super.init(appManager: appManager)

            let languageCode = Locale.current.language.languageCode?.identifier ?? ""
            self.localeLanguageRegions = Self.primaryRegions(for: languageCode)

            self.allEntries = CallingCodeEntry.allCases
                .sorted { self.sortKey($0) < self.sortKey($1) }

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

        // MARK: - Private

        /// Returns ISO region codes where `languageCode` is the primary language,
        /// using CLDR likely-subtags via `Locale.Language.maximalIdentifier` (iOS 16+).
        private static func primaryRegions(for languageCode: String) -> Set<String> {
            guard !languageCode.isEmpty else { return [] }
            guard #available(iOS 16, *) else { return [] }
            return Set(Locale.Region.isoRegions.compactMap { region -> String? in
                let regionCode = region.identifier
                let maximal = Locale.Language(identifier: "und-\(regionCode)").maximalIdentifier
                guard let primary = maximal.split(separator: "-").first,
                      String(primary) == languageCode else { return nil }
                return regionCode
            })
        }

        /// Sort key: (bucket, numericCode).
        /// Buckets: 0 = Israel, 1 = locale-language countries, 2 = rest.
        /// Within each bucket, entries are ordered by numeric calling code.
        private func sortKey(_ entry: CallingCodeEntry) -> (Int, Int) {
            let numeric = Int(entry.callingCode.dropFirst()) ?? Int.max
            switch entry.callingCode {
            case "+972":
                return (0, numeric)
            default:
                if entry.isoCountryCodes.contains(where: { localeLanguageRegions.contains($0) }) {
                    return (1, numeric)
                }
                return (2, numeric)
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
        CountryListView(model: CountryListView.ViewModel(appManager: AppManager.previews))
    }
}
