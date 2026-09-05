//
//  FilterListRowView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 07/02/2022.
//

import SwiftUI
import NaturalLanguage


//MARK: - View -
struct FilterListRowView: View {

    var dotFilterID: UUID?
    var focusedFilterID: FocusState<UUID?>.Binding
    @ObservedObject var model: ViewModel
    var isOptionsCollapsed: Bool = false
    @State private var isEditingText = false
    @State private var showDuplicateError = false
    @State private var showInvalidRegexError = false
    @State private var dotOpacity: Double = 0

    var body: some View {
        AdaptiveRow {
            EmptyView()
        } content: {
            filterTextColumn
        } trailing: {
            if !self.isEditingText {
                optionButtons
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var filterTextColumn: some View {
        HStack(alignment: .center) {
            Circle()
                .fill(.tint)
                .frame(width: 8, height: 8)
                .opacity(dotOpacity)
                .onAppear {
                    guard dotFilterID == model.id, dotOpacity == 0 else { return }
                    dotOpacity = 1.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        withAnimation(.easeOut(duration: 1.0)) {
                            dotOpacity = 0.0
                        }
                    }
                }
                .onChange(of: dotFilterID) { newID in
                    guard newID == model.id, dotOpacity == 0 else { return }
                    dotOpacity = 1.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        withAnimation(.easeOut(duration: 1.0)) {
                            dotOpacity = 0.0
                        }
                    }
                }

            if self.model.filter.filterType == .denyLanguage,
               let filterText = self.model.filter.text {
                let blockedLanguage = NLLanguage(filterText: filterText)
                if blockedLanguage != .undetermined,
                   let localizedName = blockedLanguage.localizedName {
                    Text(localizedName)
                }
            }
            else {
                EditableText(
                    $model.text,
                    focusID: model.id,
                    focusedID: focusedFilterID,
                    minimumCharacters: kMinimumFilterLength,
                    attributedText: self.model.filter.filterMatching == .regex ? { $0.highlightedAsRegex } : nil,
                    onCommit: {
                        self.model.updateFilter(filterText: self.model.text)
                        self.showDuplicateError = false
                        self.showInvalidRegexError = false
                    },
                    onEditingChanged: { isEditing in
                        withAnimation {
                            self.isEditingText = isEditing
                            if !isEditing {
                                self.showDuplicateError = false
                                self.showInvalidRegexError = false
                            }
                        }
                    },
                    onTextChange: { text in
                        self.showDuplicateError = self.model.isLiveDuplicate(text: text)
                        self.showInvalidRegexError = self.model.isLiveInvalidRegex(text: text)
                    })
                    .font(self.model.filter.filterMatching == .regex ? .system(.body, design: .monospaced) : .body)
                    .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                    .layoutPriority(1)

                if self.isEditingText && self.showDuplicateError {
                    FilterBadge(text: "addFilter_duplicate"~, color: .red, systemImage: "xmark.circle.fill")
                } else if self.isEditingText && self.showInvalidRegexError {
                    FilterBadge(text: "addFilter_invalidRegex"~, color: .red, systemImage: "xmark.circle.fill")
                }
            }
        }
    }

    @ViewBuilder
    private var optionButtons: some View {
        if isOptionsCollapsed {
            if self.model.filter.filterType.supportsAdvancedOptions ||
                self.model.filter.filterType.supportsFolders {
                collapsedOptionsMenu
            }
        } else {
            HStack(spacing: 8) {
                if self.model.filter.filterType.supportsAdvancedOptions {
                    targetMenu
                    if self.model.filter.filterMatching != .regex {
                        matchingMenu
                        caseMenu
                    }
                }
                if self.model.filter.filterType.supportsFolders {
                    folderMenu
                }
            }
        }
    }

    @ViewBuilder
    private var collapsedOptionsMenu: some View {
        Menu {
            if self.model.filter.filterType.supportsAdvancedOptions {
                targetPicker

                if self.model.filter.filterMatching != .regex {
                    Divider()
                    matchingPicker
                    Divider()
                    casePicker
                }
            }
            if self.model.filter.filterType.supportsFolders {
                Divider()
                folderPicker
            }
        } label: {
            FilterRowOptionChip(systemName: "slider.horizontal.3", isActive: true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("filterList_options"~)
    }

    @ViewBuilder
    private var targetMenu: some View {
        Menu {
            targetPicker
        } label: {
            FilterRowOptionChip(systemName: self.model.filter.filterTarget.icon,
                                isActive: self.model.filter.filterTarget != .all)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(self.model.filter.filterMatching == .regex
            ? String(format: "a11y_filterRow_targetLabel"~, self.model.filter.filterTarget.name) + ", " + String(format: "a11y_filterRow_matchLabel"~, FilterMatching.regex.name)
            : String(format: "a11y_filterRow_targetLabel"~, self.model.filter.filterTarget.name))
    }

    @ViewBuilder
    private var matchingMenu: some View {
        Menu {
            matchingPicker
        } label: {
            FilterRowOptionChip(systemName: self.model.filter.filterMatching.icon,
                                isActive: self.model.filter.filterMatching == .exact)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(format: "a11y_filterRow_matchLabel"~, self.model.filter.filterMatching.name))
    }

    @ViewBuilder
    private var caseMenu: some View {
        Menu {
            casePicker
        } label: {
            FilterRowOptionChip(systemName: self.model.filter.filterCase.icon,
                                isActive: self.model.filter.filterCase == .caseSensitive)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(format: "a11y_filterRow_caseLabel"~, self.model.filter.filterCase.name))
    }

    @ViewBuilder
    private var folderMenu: some View {
        Menu {
            folderPicker
        } label: {
            FilterRowOptionChip(systemName: self.model.filter.denyFolderType.iconName, isActive: true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(format: "a11y_filterRow_folderLabel"~, self.model.filter.denyFolderType.name))
    }

    private var targetPicker: some View {
        Picker(selection: Binding(
            get: { self.model.filter.filterTarget },
            set: { self.model.updateFilter(filterTarget: $0) }
        )) {
            ForEach(FilterTarget.allCases) { filterTarget in
                Label(filterTarget.name, systemImage: filterTarget.icon)
                    .tag(filterTarget)
            }
        } label: {
            EmptyView()
        }
    }

    private var matchingPicker: some View {
        Picker(selection: Binding(
            get: { self.model.filter.filterMatching },
            set: { self.model.updateFilter(filterMatching: $0) }
        )) {
            ForEach(FilterMatching.allCases.filter { $0 != .regex }) { filterMatching in
                Label(filterMatching.name, systemImage: filterMatching.icon)
                    .tag(filterMatching)
            }
        } label: {
            EmptyView()
        }
    }

    private var casePicker: some View {
        Picker(selection: Binding(
            get: { self.model.filter.filterCase },
            set: { self.model.updateFilter(filterCase: $0) }
        )) {
            ForEach(FilterCase.allCases) { filterCase in
                Label(filterCase.name, systemImage: filterCase.icon)
                    .tag(filterCase)
            }
        } label: {
            EmptyView()
        }
    }

    private var folderPicker: some View {
        Picker(selection: Binding(
            get: { self.model.filter.denyFolderType },
            set: { self.model.updateFilter(denyFolder: $0) }
        )) {
            ForEach(DenyFolderType.allCases) { folder in
                Label(folder.name, systemImage: folder.iconName)
                    .tag(folder)
            }
        } label: {
            EmptyView()
        }
    }
}

//MARK: - View Model -
extension FilterListRowView {
    
    class ViewModel: BaseViewModel, ObservableObject {
        let id: UUID
        @Published private(set) var filter: Filter
        @Published private(set) var onUpdate: ((Bool) -> ())?
        @Published var text: String

        init(filter: Filter,
             onUpdate: ((Bool) -> ())? = nil,
             appManager: AppManagerProtocol = AppManager.shared) {

            if let uuid = filter.uuid {
                self.id = uuid
            }
            else {
                let uuid = UUID()
                filter.uuid = uuid
                self.id = uuid
            }
            self.filter = filter
            self.onUpdate = onUpdate
            self.text = filter.text ?? "general_null"~
            super.init(appManager: appManager)
        }

        func updateFilter(_ filter: Filter) {
            let previousText = self.filter.text ?? ""
            self.filter = filter
            if self.text == previousText {
                self.text = filter.text ?? "general_null"~
            }
        }
        
        func updateFilter(denyFolder: DenyFolderType) {
            self.appManager.persistanceManager.updateFilter(self.filter, denyFolder: denyFolder)
            self.onUpdate?(true)
        }
        
        func updateFilter(filterMatching: FilterMatching) {
            self.appManager.persistanceManager.updateFilter(self.filter, filterMatching: filterMatching)
            self.onUpdate?(true)
        }
        
        func updateFilter(filterCase: FilterCase) {
            self.appManager.persistanceManager.updateFilter(self.filter, filterCase: filterCase)
            self.onUpdate?(true)
        }
        
        func updateFilter(filterTarget: FilterTarget) {
            self.appManager.persistanceManager.updateFilter(self.filter, filterTarget: filterTarget)
            self.onUpdate?(true)
        }
        
        func isLiveDuplicate(text: String) -> Bool {
            guard text != (self.filter.text ?? "") else { return false }
            return self.appManager.persistanceManager.isDuplicateFilter(
                text: text,
                filterTarget: self.filter.filterTarget,
                filterMatching: self.filter.filterMatching,
                filterCase: self.filter.filterCase)
        }

        func isLiveInvalidRegex(text: String) -> Bool {
            guard self.filter.filterMatching == .regex, !text.isEmpty else { return false }
            return (try? Regex(text)) == nil
        }

        @discardableResult
        func updateFilter(filterText: String) -> Bool {
            let current = self.filter.text ?? ""

            guard filterText != current else {
                AppManager.logger.debug("FilterListRow.updateFilter(text) — skipped, unchanged")
                return false
            }

            if self.filter.filterMatching == .regex, (try? Regex(filterText)) == nil {
                AppManager.logger.debug("FilterListRow.updateFilter(text) — skipped, invalid regex")
                self.text = current
                return true
            }

            guard !self.appManager.persistanceManager.isDuplicateFilter(
                text: filterText,
                filterTarget: self.filter.filterTarget,
                filterMatching: self.filter.filterMatching,
                filterCase: self.filter.filterCase) else {
                AppManager.logger.debug("FilterListRow.updateFilter(text) — skipped, duplicate")
                self.text = current
                return true
            }

            AppManager.logger.debug("FilterListRow.updateFilter(text) — saving")
            self.appManager.persistanceManager.updateFilter(self.filter, filterText: filterText)
            if self.filter.text != filterText {
                self.text = self.filter.text ?? current
                return true
            }
            self.onUpdate?(false)
            return false
        }
    }
}


//MARK: - Preview -
struct FilterListRowView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FilterListView(model: FilterListView.ViewModel(filterType: .deny, appManager: AppManager.previews))
        }
    }
}
