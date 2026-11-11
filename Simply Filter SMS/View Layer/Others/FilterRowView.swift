//
//  FilterRowView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 07/02/2022.
//

import SwiftUI
import NaturalLanguage


//MARK: - View -
struct FilterRowView: View {

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
                .onChange(of: dotFilterID) { _, newID in
                    guard newID == model.id, dotOpacity == 0 else { return }
                    dotOpacity = 1.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        withAnimation(.easeOut(duration: 1.0)) {
                            dotOpacity = 0.0
                        }
                    }
                }

            if self.model.filterType == .denyLanguage,
               !self.model.committedText.isEmpty {
                let blockedLanguage = NLLanguage(filterText: self.model.committedText)
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
                    attributedText: self.model.filterMatching == .regex ? { $0.highlightedAsRegex } : nil,
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
                    .font(self.model.filterMatching == .regex ? .system(.body, design: .monospaced) : .body)
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
            if self.model.filterType.supportsAdvancedOptions ||
                self.model.filterType.supportsFolders {
                collapsedOptionsMenu
            }
        } else {
            HStack(spacing: 8) {
                if self.model.filterType.supportsAdvancedOptions {
                    targetMenu
                    if self.model.filterMatching != .regex {
                        matchingMenu
                        caseMenu
                    }
                }
                if self.model.filterType.supportsFolders {
                    folderMenu
                }
            }
        }
    }

    @ViewBuilder
    private var collapsedOptionsMenu: some View {
        Menu {
            if self.model.filterType.supportsAdvancedOptions {
                targetPicker

                if self.model.filterMatching != .regex {
                    Divider()
                    matchingPicker
                    Divider()
                    casePicker
                }
            }
            if self.model.filterType.supportsFolders {
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
            FilterRowOptionChip(systemName: self.model.filterTarget.icon,
                                isActive: self.model.filterTarget != .all)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(self.model.filterMatching == .regex
            ? String(format: "a11y_filterRow_targetLabel"~, self.model.filterTarget.name) + ", " + String(format: "a11y_filterRow_matchLabel"~, FilterMatching.regex.name)
            : String(format: "a11y_filterRow_targetLabel"~, self.model.filterTarget.name))
    }

    @ViewBuilder
    private var matchingMenu: some View {
        Menu {
            matchingPicker
        } label: {
            FilterRowOptionChip(systemName: self.model.filterMatching.icon,
                                isActive: self.model.filterMatching == .exact)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(format: "a11y_filterRow_matchLabel"~, self.model.filterMatching.name))
    }

    @ViewBuilder
    private var caseMenu: some View {
        Menu {
            casePicker
        } label: {
            FilterRowOptionChip(systemName: self.model.filterCase.icon,
                                isActive: self.model.filterCase == .caseSensitive)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(format: "a11y_filterRow_caseLabel"~, self.model.filterCase.name))
    }

    @ViewBuilder
    private var folderMenu: some View {
        Menu {
            folderPicker
        } label: {
            FilterRowOptionChip(systemName: self.model.messageFolder.iconName, isActive: true)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(format: "a11y_filterRow_folderLabel"~, self.model.messageFolder.name))
    }

    private var targetPicker: some View {
        Picker(selection: Binding(
            get: { self.model.filterTarget },
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
            get: { self.model.filterMatching },
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
            get: { self.model.filterCase },
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
            get: { self.model.messageFolder },
            set: { self.model.updateFilter(denyFolder: $0) }
        )) {
            ForEach(MessageFolder.allCases) { folder in
                Label(folder.name, systemImage: folder.iconName)
                    .tag(folder)
            }
        } label: {
            EmptyView()
        }
    }
}

//MARK: - View Model -
extension FilterRowView {
    
    class ViewModel: BaseViewModel, ObservableObject {
        let id: UUID
        @Published private(set) var filter: Filter
        @Published private(set) var onUpdate: ((Bool) -> ())?
        @Published var text: String
        @Published private(set) var committedText: String
        @Published private(set) var filterType: FilterType
        @Published private(set) var filterTarget: FilterTarget
        @Published private(set) var filterMatching: FilterMatching
        @Published private(set) var filterCase: FilterCase
        @Published private(set) var messageFolder: MessageFolder

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
            self.committedText = filter.text ?? ""
            self.filterType = filter.filterType
            self.filterTarget = filter.filterTarget
            self.filterMatching = filter.filterMatching
            self.filterCase = filter.filterCase
            self.messageFolder = filter.messageFolder
            super.init(appManager: appManager)
        }

        func updateFilter(_ filter: Filter) {
            let previousText = self.committedText
            self.filter = filter
            self.committedText = filter.text ?? ""
            if self.text == previousText {
                self.text = filter.text ?? "general_null"~
            }
            self.cacheOptions()
        }
        
        func updateFilter(denyFolder: MessageFolder) {
            self.appManager.persistenceManager.updateFilter(self.filter, denyFolder: denyFolder)
            self.onUpdate?(true)
        }
        
        func updateFilter(filterMatching: FilterMatching) {
            self.appManager.persistenceManager.updateFilter(self.filter, filterMatching: filterMatching)
            self.onUpdate?(true)
        }
        
        func updateFilter(filterCase: FilterCase) {
            self.appManager.persistenceManager.updateFilter(self.filter, filterCase: filterCase)
            self.onUpdate?(true)
        }
        
        func updateFilter(filterTarget: FilterTarget) {
            self.appManager.persistenceManager.updateFilter(self.filter, filterTarget: filterTarget)
            self.onUpdate?(true)
        }
        
        func isLiveDuplicate(text: String) -> Bool {
            guard text != self.committedText else { return false }
            return self.appManager.persistenceManager.isDuplicateFilter(
                text: text,
                filterTarget: self.filterTarget,
                filterMatching: self.filterMatching,
                filterCase: self.filterCase)
        }

        func isLiveInvalidRegex(text: String) -> Bool {
            guard self.filterMatching == .regex, !text.isEmpty else { return false }
            return (try? Regex(text)) == nil
        }

        @discardableResult
        func updateFilter(filterText: String) -> Bool {
            let current = self.committedText

            guard filterText != current else {
                Log.debug("text unchanged, text: \(current) → skipped")
                return false
            }

            if self.filterMatching == .regex, (try? Regex(filterText)) == nil {
                Log.debug("invalid regex, text: \(filterText), current: \(current) → reverted")
                self.text = current
                return true
            }

            guard !self.appManager.persistenceManager.isDuplicateFilter(
                text: filterText,
                filterTarget: self.filterTarget,
                filterMatching: self.filterMatching,
                filterCase: self.filterCase) else {
                Log.debug("duplicate, text: \(filterText), current: \(current) → reverted")
                self.text = current
                return true
            }

            self.appManager.persistenceManager.updateFilter(self.filter, filterText: filterText)

            guard self.filter.text == filterText else {
                Log.debug("save failed, text: \(filterText), current: \(current) → reverted")
                self.text = current
                return true
            }

            self.committedText = filterText
            self.onUpdate?(false)
            return false
        }

        private func cacheOptions() {
            self.filterType = self.filter.filterType
            self.filterTarget = self.filter.filterTarget
            self.filterMatching = self.filter.filterMatching
            self.filterCase = self.filter.filterCase
            self.messageFolder = self.filter.messageFolder
        }
    }
}


//MARK: - Preview -
struct FilterRowView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FiltersView(model: FiltersView.ViewModel(filterType: .deny, appManager: AppManager.previews))
        }
    }
}
