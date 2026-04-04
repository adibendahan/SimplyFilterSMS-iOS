//
//  FilterListRowView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 07/02/2022.
//

import SwiftUI
import CoreData
import NaturalLanguage


//MARK: - View -
struct FilterListRowView: View {

    var filterObjectID: NSManagedObjectID
    var dotFilterID: NSManagedObjectID?
    @ObservedObject var model: ViewModel
    @State private var isEditingText = false
    @State private var showDuplicateError = false
    @State private var showInvalidRegexError = false
    @State private var dotOpacity: Double = 0

    @ScaledMetric(relativeTo: .body) private var optionIconSize: CGFloat = 15

    var body: some View {
        HStack (alignment: .center) {

            Circle()
                .fill(Color.accentColor)
                .frame(width: 8, height: 8)
                .opacity(dotOpacity)
                .onAppear {
                    guard dotFilterID == filterObjectID, dotOpacity == 0 else { return }
                    dotOpacity = 1.0
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                        withAnimation(.easeOut(duration: 1.0)) {
                            dotOpacity = 0.0
                        }
                    }
                }
                .onChange(of: dotFilterID) { newID in
                    guard newID == filterObjectID, dotOpacity == 0 else { return }
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
                    minimumCharacters: 3,
                    attributedText: self.model.filter.filterMatching == .regex ? { $0.highlightedAsRegex } : nil,
                    onCommit: {
                        self.model.updateFilter(filterText: self.model.text)
                        self.showDuplicateError = false
                        self.showInvalidRegexError = false
                        self.isEditingText = false
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

                if self.isEditingText && self.showDuplicateError {
                    FilterBadge(text: "addFilter_duplicate"~, color: .red, systemImage: "xmark.circle.fill")
                } else if self.isEditingText && self.showInvalidRegexError {
                    FilterBadge(text: "addFilter_invalidRegex"~, color: .red, systemImage: "xmark.circle.fill")
                }
            }
            
            Spacer()
            
            if !self.isEditingText && self.model.filter.filterType.supportsAdvancedOptions {
                Menu {
                    ForEach(FilterTarget.allCases) { filterTarget in
                        Button {
                            self.model.updateFilter(filterTarget: filterTarget)
                        } label: {
                            Label(filterTarget.name, systemImage: filterTarget.icon)
                        }
                    }
                } label: {
                    OptionButton(image: Image(systemName: self.model.filter.filterTarget.icon),
                                 isActive: self.model.filter.filterTarget != .all)
                }
                .accessibilityLabel(String(format: "a11y_filterRow_targetLabel"~, self.model.filter.filterTarget.name))

                if self.model.filter.filterMatching != .regex {
                    Menu {
                        ForEach(FilterMatching.allCases.filter { $0 != .regex }) { filterMatching in
                            Button {
                                self.model.updateFilter(filterMatching: filterMatching)
                            } label: {
                                Label(filterMatching.name, systemImage: filterMatching.icon)
                            }
                        }
                    } label: {
                        OptionButton(image: Image(systemName: self.model.filter.filterMatching.icon),
                                     isActive: self.model.filter.filterMatching == .exact)
                    }
                    .accessibilityLabel(String(format: "a11y_filterRow_matchLabel"~, self.model.filter.filterMatching.name))

                    Menu {
                        ForEach(FilterCase.allCases) { filterCase in
                            Button {
                                self.model.updateFilter(filterCase: filterCase)
                            } label: {
                                Label(filterCase.name, systemImage: filterCase.icon)
                            }
                        }
                    } label: {
                        OptionButton(image: Image(systemName: self.model.filter.filterCase.icon),
                                     isActive: self.model.filter.filterCase == .caseSensitive)
                    }
                    .accessibilityLabel(String(format: "a11y_filterRow_caseLabel"~, self.model.filter.filterCase.name))
                } else {
                    OptionButton(image: Image(systemName: FilterMatching.regex.icon), isActive: true)
                        .accessibilityLabel(String(format: "a11y_filterRow_matchLabel"~, FilterMatching.regex.name))
                        .allowsHitTesting(false)
                }
            }

            if !self.isEditingText && self.model.filter.filterType.supportsFolders {
                Menu {
                    ForEach(DenyFolderType.allCases) { folder in
                        Button {
                            self.model.updateFilter(denyFolder: folder)
                        } label: {
                            Label(folder.name, systemImage: folder.iconName)
                        }
                    }
                } label: {
                    OptionButton(image: Image(systemName: self.model.filter.denyFolderType.iconName), isActive: true)
                }
                .accessibilityLabel(String(format: "a11y_filterRow_folderLabel"~, self.model.filter.denyFolderType.name))
            }
        }  // HStack
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func OptionButton(image: Image, isActive: Bool) -> some View {
        let color: Color = isActive ? .green : .secondary
        image
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(color)
            .frame(width: optionIconSize, height: optionIconSize)
            .padding(7)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(.white.opacity(0.25), lineWidth: 0.5)
            )
    }
}

//MARK: - View Model -
extension FilterListRowView {
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published private(set) var filter: Filter
        @Published private(set) var onUpdate: ((Bool) -> ())?
        @Published var text: String

        init(filter: Filter,
             onUpdate: ((Bool) -> ())? = nil,
             appManager: AppManagerProtocol = AppManager.shared) {

            self.filter = filter
            self.onUpdate = onUpdate
            self.text = filter.text ?? "general_null"~
            super.init(appManager: appManager)
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
            guard filterText != self.filter.text else { return false }

            if self.filter.filterMatching == .regex, (try? Regex(filterText)) == nil {
                self.text = self.filter.text ?? ""
                return true
            }

            guard !self.appManager.persistanceManager.isDuplicateFilter(
                text: filterText,
                filterTarget: self.filter.filterTarget,
                filterMatching: self.filter.filterMatching,
                filterCase: self.filter.filterCase) else {
                self.text = self.filter.text ?? ""
                return true
            }

            self.appManager.persistanceManager.updateFilter(self.filter, filterText: filterText)
            self.onUpdate?(false)
            return false
        }
    }
}


//MARK: - Preview -
struct FilterListRowView_Previews: PreviewProvider {
    static var previews: some View {
        let appManager = AppManager.previews
        let filter = appManager.persistanceManager.fetchFilterRecords(for: .deny).first!
        
        FilterListRowView(filterObjectID: filter.objectID, dotFilterID: nil, model: FilterListRowView.ViewModel(filter: filter, appManager: appManager))
            .padding()
    }
}
