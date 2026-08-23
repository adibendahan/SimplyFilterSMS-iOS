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
    @Environment(\.editMode) private var editMode
    @State private var isEditingText = false
    @State private var showDuplicateError = false
    @State private var showInvalidRegexError = false
    @State private var dotOpacity: Double = 0

    @ScaledMetric(relativeTo: .body) private var optionIconSize: CGFloat = 15

    private var showOptionChrome: Bool {
        !self.isEditingText && self.editMode?.wrappedValue.isEditing != true
    }

    var body: some View {
        HStack (alignment: .center) {

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

            if self.model.filterType == .denyLanguage {
                let blockedLanguage = NLLanguage(filterText: self.model.text)
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

                if self.isEditingText && self.showDuplicateError {
                    FilterBadge(text: "addFilter_duplicate"~, color: .red, systemImage: "xmark.circle.fill")
                } else if self.isEditingText && self.showInvalidRegexError {
                    FilterBadge(text: "addFilter_invalidRegex"~, color: .red, systemImage: "xmark.circle.fill")
                }
            }
            
            Spacer()
            
            Group {
                if self.model.filterType.supportsAdvancedOptions {
                    Menu {
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
                    } label: {
                        OptionButton(image: Image(systemName: self.model.filterTarget.icon),
                                     isActive: self.model.filterTarget != .all)
                    }
                    .accessibilityLabel(self.model.filterMatching == .regex
                        ? String(format: "a11y_filterRow_targetLabel"~, self.model.filterTarget.name) + ", " + String(format: "a11y_filterRow_matchLabel"~, FilterMatching.regex.name)
                        : String(format: "a11y_filterRow_targetLabel"~, self.model.filterTarget.name))

                    if self.model.filterMatching != .regex {
                        Menu {
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
                        } label: {
                            OptionButton(image: Image(systemName: self.model.filterMatching.icon),
                                         isActive: self.model.filterMatching == .exact)
                        }
                        .accessibilityLabel(String(format: "a11y_filterRow_matchLabel"~, self.model.filterMatching.name))

                        Menu {
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
                        } label: {
                            OptionButton(image: Image(systemName: self.model.filterCase.icon),
                                         isActive: self.model.filterCase == .caseSensitive)
                        }
                        .accessibilityLabel(String(format: "a11y_filterRow_caseLabel"~, self.model.filterCase.name))
                    }
                }

                if self.model.filterType.supportsFolders {
                    Menu {
                        Picker(selection: Binding(
                            get: { self.model.denyFolderType },
                            set: { self.model.updateFilter(denyFolder: $0) }
                        )) {
                            ForEach(DenyFolderType.allCases) { folder in
                                Label(folder.name, systemImage: folder.iconName)
                                    .tag(folder)
                            }
                        } label: {
                            EmptyView()
                        }
                    } label: {
                        OptionButton(image: Image(systemName: self.model.denyFolderType.iconName), isActive: true)
                    }
                    .accessibilityLabel(String(format: "a11y_filterRow_folderLabel"~, self.model.denyFolderType.name))
                }
            }
            .opacity(self.showOptionChrome ? 1 : 0)
            .allowsHitTesting(self.showOptionChrome)
        }  // HStack
        .allowsHitTesting(self.editMode?.wrappedValue.isEditing != true)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func OptionButton(image: Image, isActive: Bool) -> some View {
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(isActive ? AnyShapeStyle(.tint) : AnyShapeStyle(.secondary))
            .frame(width: optionIconSize, height: optionIconSize)
            .padding(7)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
            )
    }
}

//MARK: - View Model -
extension FilterListRowView {
    
    class ViewModel: BaseViewModel, ObservableObject {
        let id: UUID
        @Published private(set) var filter: Filter
        @Published private(set) var filterType: FilterType
        @Published private(set) var denyFolderType: DenyFolderType
        @Published private(set) var filterTarget: FilterTarget
        @Published private(set) var filterMatching: FilterMatching
        @Published private(set) var filterCase: FilterCase
        @Published private(set) var onUpdate: ((Bool) -> ())?
        @Published var text: String
        private var committedText: String

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
            self.filterType = filter.filterType
            self.denyFolderType = filter.denyFolderType
            self.filterTarget = filter.filterTarget
            self.filterMatching = filter.filterMatching
            self.filterCase = filter.filterCase
            self.onUpdate = onUpdate
            let initialText = filter.text ?? "general_null"~
            self.text = initialText
            self.committedText = initialText
            super.init(appManager: appManager)
        }

        func updateFilter(_ filter: Filter) {
            let previousText = self.committedText
            self.filter = filter
            self.filterType = filter.filterType
            self.denyFolderType = filter.denyFolderType
            self.filterTarget = filter.filterTarget
            self.filterMatching = filter.filterMatching
            self.filterCase = filter.filterCase
            let updatedText = filter.text ?? "general_null"~
            self.committedText = updatedText
            if self.text == previousText {
                self.text = updatedText
            }
        }
        
        func updateFilter(denyFolder: DenyFolderType) {
            self.denyFolderType = denyFolder
            self.appManager.persistanceManager.updateFilter(self.filter, denyFolder: denyFolder)
            self.onUpdate?(true)
        }
        
        func updateFilter(filterMatching: FilterMatching) {
            self.filterMatching = filterMatching
            self.appManager.persistanceManager.updateFilter(self.filter, filterMatching: filterMatching)
            self.onUpdate?(true)
        }
        
        func updateFilter(filterCase: FilterCase) {
            self.filterCase = filterCase
            self.appManager.persistanceManager.updateFilter(self.filter, filterCase: filterCase)
            self.onUpdate?(true)
        }
        
        func updateFilter(filterTarget: FilterTarget) {
            self.filterTarget = filterTarget
            self.appManager.persistanceManager.updateFilter(self.filter, filterTarget: filterTarget)
            self.onUpdate?(true)
        }
        
        func isLiveDuplicate(text: String) -> Bool {
            guard text != self.committedText else { return false }
            return self.appManager.persistanceManager.isDuplicateFilter(
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
            AppManager.logger.debug("FilterListRow.updateFilter(text) — proposed: '\(filterText, privacy: .public)', current: '\(self.committedText, privacy: .public)'")

            guard filterText != self.committedText else {
                AppManager.logger.debug("FilterListRow.updateFilter(text) — skipped, unchanged")
                return false
            }

            if self.filterMatching == .regex, (try? Regex(filterText)) == nil {
                AppManager.logger.debug("FilterListRow.updateFilter(text) — skipped, invalid regex")
                self.text = self.committedText
                return true
            }

            guard !self.appManager.persistanceManager.isDuplicateFilter(
                text: filterText,
                filterTarget: self.filterTarget,
                filterMatching: self.filterMatching,
                filterCase: self.filterCase) else {
                AppManager.logger.debug("FilterListRow.updateFilter(text) — skipped, duplicate")
                self.text = self.committedText
                return true
            }

            AppManager.logger.debug("FilterListRow.updateFilter(text) — saving")
            self.appManager.persistanceManager.updateFilter(self.filter, filterText: filterText)
            self.committedText = filterText
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
