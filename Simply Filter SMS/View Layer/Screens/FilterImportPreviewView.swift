//
//  FilterImportPreviewView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 15/08/2026.
//

import SwiftUI
import NaturalLanguage


//MARK: - View -
struct FilterImportPreviewView: View {

    @Environment(\.dismiss)
    var dismiss

    @StateObject var model: ViewModel
    @ScaledMetric(relativeTo: .body) private var typeIconSize: CGFloat = 20

    init(model: ViewModel) {
        _model = StateObject(wrappedValue: model)
    }

    var body: some View {
        NavigationView {
            List {
                Section {
                    ForEach(FilterType.allCases
                        .sorted(by: { $0.sortIndex < $1.sortIndex })
                        .filter({ self.model.candidates(for: $0).isEmpty == false }), id: \.self) { filterType in
                        NavigationLink {
                            FilterImportCandidateListView(model: self.model, filterType: filterType)
                        } label: {
                            HStack {
                                Image(systemName: filterType.iconName)
                                    .foregroundColor(filterType.iconColor)
                                    .frame(maxWidth: typeIconSize, maxHeight: .infinity, alignment: .center)

                                Text(filterType.name)
                                    .padding(.leading, 8)

                                Spacer()

                                Text(String.localizedStringWithFormat("general_active_count"~, self.model.selectedCount(for: filterType)))
                                    .textCase(.uppercase)
                                    .foregroundColor(.secondary)
                                    .font(Font.caption2)
                            }
                        }
                        .accentColor(Color.primary.opacity(0.35))
                    }
                } header: {
                    Text("importFilters_sectionTitle"~)
                        .accessibilityAddTraits(.isHeader)
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("importFilters_subtitle"~)

                        if self.model.preview.duplicateCount > 0 {
                            Text("importFilters_duplicates"~ + ": \(self.model.preview.duplicateCount)")
                        }

                        if self.model.preview.invalidCount > 0 {
                            Text("importFilters_invalid"~ + ": \(self.model.preview.invalidCount)")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("importFilters_title"~)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        self.dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("general_close"~)
                    .contentShape(Rectangle())
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("importFilters_confirm"~) {
                        self.model.confirm()
                        self.dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(self.model.selectedCount == 0)
                }
            }
        }
    }
}


//MARK: - Candidate List -
struct FilterImportCandidateListView: View {

    @ObservedObject var model: FilterImportPreviewView.ViewModel
    let filterType: FilterType

    @ScaledMetric(relativeTo: .body) private var optionIconSize: CGFloat = 15

    var body: some View {
        List(selection: self.$model.selectedIDs) {
            Section {
                ForEach(self.model.regularCandidates(for: self.filterType)) { candidate in
                    self.candidateRow(candidate)
                }
            } header: {
                if self.model.regularCandidates(for: self.filterType).count > 0 {
                    HStack {
                        self.sectionSelectAll(self.model.regularCandidates(for: self.filterType))

                        Text(self.filterType == .denyLanguage ? "general_lang"~ : "filterList_text"~)

                        Spacer()

                        Text(self.filterType.supportsAdvancedOptions ? "filterList_options"~ : "filterList_folder"~)
                            .padding(.trailing, 8)
                    }
                }
            }

            if self.model.regexCandidates(for: self.filterType).count > 0 {
                Section {
                    ForEach(self.model.regexCandidates(for: self.filterType)) { candidate in
                        self.candidateRow(candidate)
                    }
                } header: {
                    HStack {
                        self.sectionSelectAll(self.model.regexCandidates(for: self.filterType))
                        Text("addFilter_match_regex"~)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .environment(\.editMode, .constant(.active))
        .navigationTitle(self.filterType.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func sectionSelectAll(_ candidates: [FilterImportCandidate]) -> some View {
        let state = self.model.selectionState(for: candidates)
        return Button {
            self.model.toggleSelection(for: candidates)
        } label: {
            Image(systemName: state == .all ? "checkmark.circle.fill" : (state == .some ? "minus.circle.fill" : "circle"))
                .foregroundColor(.accentColor)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(state == .all ? "importFilters_selectNone"~ : "importFilters_selectAll"~)
    }

    @ViewBuilder
    private func candidateRow(_ candidate: FilterImportCandidate) -> some View {
        HStack(alignment: .center) {
            Text(self.model.displayName(for: candidate))
                .font(candidate.filterMatching == .regex ? .system(.body, design: .monospaced) : .body)
                .foregroundColor(.primary)

            Spacer()

            if candidate.type.supportsAdvancedOptions {
                self.optionIcon(systemName: candidate.filterTarget.icon,
                                isActive: candidate.filterTarget != .all)

                if candidate.filterMatching != .regex {
                    self.optionIcon(systemName: candidate.filterMatching.icon,
                                    isActive: candidate.filterMatching == .exact)

                    self.optionIcon(systemName: candidate.filterCase.icon,
                                    isActive: candidate.filterCase == .caseSensitive)
                }
            }

            if candidate.type.supportsFolders {
                self.optionIcon(systemName: candidate.denyFolder.iconName, isActive: true)
            }
        }
        .tag(candidate.id)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(self.candidateAccessibilityLabel(candidate))
    }

    private func candidateAccessibilityLabel(_ candidate: FilterImportCandidate) -> String {
        var parts = [self.model.displayName(for: candidate)]
        if candidate.type.supportsAdvancedOptions {
            parts.append(String(format: "a11y_filterRow_targetLabel"~, candidate.filterTarget.name))
            parts.append(String(format: "a11y_filterRow_matchLabel"~, candidate.filterMatching.name))
            if candidate.filterMatching != .regex {
                parts.append(String(format: "a11y_filterRow_caseLabel"~, candidate.filterCase.name))
            }
        }
        if candidate.type.supportsFolders {
            parts.append(String(format: "a11y_filterRow_folderLabel"~, candidate.denyFolder.name))
        }
        return parts.joined(separator: ", ")
    }

    private func optionIcon(systemName: String, isActive: Bool) -> some View {
        let color: Color = isActive ? .green : .secondary
        return Image(systemName: systemName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(color)
            .frame(width: self.optionIconSize, height: self.optionIconSize)
            .padding(7)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
            )
            .accessibilityHidden(true)
    }
}


//MARK: - ViewModel -
extension FilterImportPreviewView {

    enum SectionSelection {
        case none, some, all
    }

    class ViewModel: BaseViewModel, ObservableObject {
        let preview: FilterImportPreview
        @Published var selectedIDs: Set<UUID>

        override init(appManager: AppManagerProtocol = AppManager.shared) {
            self.preview = appManager.filterImportExportManager.pendingPreview
            self.selectedIDs = Set(self.preview.toAdd.map({ $0.id }))
            super.init(appManager: appManager)
        }

        var selectedCount: Int {
            return self.selectedIDs.count
        }

        func candidates(for type: FilterType) -> [FilterImportCandidate] {
            return self.preview.toAdd.filter({ $0.type == type })
        }

        func regularCandidates(for type: FilterType) -> [FilterImportCandidate] {
            return self.candidates(for: type).filter({ $0.filterMatching != .regex })
        }

        func regexCandidates(for type: FilterType) -> [FilterImportCandidate] {
            return self.candidates(for: type).filter({ $0.filterMatching == .regex })
        }

        func selectedCount(for type: FilterType) -> Int {
            return self.candidates(for: type).filter({ self.selectedIDs.contains($0.id) }).count
        }

        func selectionState(for candidates: [FilterImportCandidate]) -> SectionSelection {
            let selected = candidates.filter({ self.selectedIDs.contains($0.id) }).count
            if selected == 0 { return .none }
            if selected == candidates.count { return .all }
            return .some
        }

        func toggleSelection(for candidates: [FilterImportCandidate]) {
            let ids = Set(candidates.map({ $0.id }))
            if self.selectionState(for: candidates) == .all {
                self.selectedIDs.subtract(ids)
            }
            else {
                self.selectedIDs.formUnion(ids)
            }
        }

        func displayName(for candidate: FilterImportCandidate) -> String {
            guard candidate.type == .denyLanguage else { return candidate.text }
            let language = NLLanguage(filterText: candidate.text)
            return language.localizedName ?? candidate.text
        }

        func confirm() {
            let selected = self.preview.toAdd.filter({ self.selectedIDs.contains($0.id) })
            guard selected.isEmpty == false else { return }

            _ = self.appManager.filterImportExportManager.importFilters(selected)
        }
    }
}


//MARK: - Preview -
struct FilterImportPreviewView_Previews: PreviewProvider {
    static var previews: some View {
        FilterImportPreviewView(model: self.previewModel())
    }

    private static func previewModel() -> FilterImportPreviewView.ViewModel {
        let appManager = AppManager.previews
        let payload = FilterExportPayload(
            format: FilterExportPayload.formatIdentifier,
            version: FilterExportPayload.currentVersion,
            exportedAt: Date(),
            appVersion: appVersion,
            filters: [
                FilterExportRecord(text: "promo",
                                   type: FilterType.deny.exportKey,
                                   folder: DenyFolderType.junk.exportKey,
                                   target: FilterTarget.body.exportKey,
                                   matching: FilterMatching.contains.exportKey,
                                   caseSensitivity: FilterCase.caseInsensitive.exportKey),
                FilterExportRecord(text: NLLanguage.english.filterText,
                                   type: FilterType.denyLanguage.exportKey,
                                   folder: DenyFolderType.junk.exportKey,
                                   target: FilterTarget.body.exportKey,
                                   matching: FilterMatching.contains.exportKey,
                                   caseSensitivity: FilterCase.caseInsensitive.exportKey)
            ]
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(payload) {
            _ = try? appManager.filterImportExportManager.queueImport(data: data)
        }
        return FilterImportPreviewView.ViewModel(appManager: appManager)
    }
}
