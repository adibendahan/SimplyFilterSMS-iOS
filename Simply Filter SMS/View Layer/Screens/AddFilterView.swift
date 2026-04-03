//
//  AddFilterView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 26/12/2021.
//

import SwiftUI


//MARK: - View -
struct AddFilterView: View {
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    @ObservedObject var model: ViewModel
    @FocusState private var focusedField: Field?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {

                    Spacer()

                    HStack (alignment: .center) {

                        ZStack(alignment: .leading) {
                            if self.model.selectedFilterMatching == .regex {
                                if self.model.filterText.isEmpty {
                                    Text("addFilter_text"~)
                                        .foregroundColor(Color(.placeholderText))
                                        .font(.system(.body, design: .monospaced))
                                        .allowsHitTesting(false)
                                } else {
                                    Text(self.model.filterText.highlightedAsRegex)
                                        .font(.system(.body, design: .monospaced))
                                        .allowsHitTesting(false)
                                }
                            }
                            TextField("addFilter_text"~, text: $model.filterText)
                                .focused($focusedField, equals: .text)
                                .accessibilityIdentifier(TestIdentifier.filterText.rawValue)
                                .font(self.model.selectedFilterMatching == .regex ? .system(.body, design: .monospaced) : .body)
                                .foregroundColor(self.model.selectedFilterMatching == .regex ? .clear : .primary)
                        }

                        if self.model.isDuplicateFilter {
                            FilterBadge(text: "addFilter_duplicate"~, color: .red, systemImage: "xmark.circle.fill")
                        } else if self.model.isInvalidRegex {
                            FilterBadge(text: "addFilter_invalidRegex"~, color: .red, systemImage: "xmark.circle.fill")
                        }
                    }

                    if self.model.isExpanded {
                        if self.model.selectedFilterMatching == .regex {
                            Group {
                                Spacer()

                                Text("addFilter_regexTestCaption"~)
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .italic()
                                    .bold()

                                HStack {
                                    TextField("addFilter_regexTestPlaceholder"~, text: $model.regexTestText)
                                        .focused($focusedField, equals: .regexTest)

                                    switch self.model.regexTestResult {
                                    case .match:
                                        FilterBadge(text: "addFilter_regexMatch"~, color: .green, systemImage: "checkmark.circle.fill")
                                    case .noMatch:
                                        FilterBadge(text: "addFilter_regexNoMatch"~, color: .red, systemImage: "xmark.circle.fill")
                                    case .invalidPattern, .empty:
                                        EmptyView()
                                    }
                                }
                            }
                            .transition(reduceMotion ? .identity : .opacity.combined(with: .move(edge: .top)))
                        }

                        Spacer()

                        Text(FilterMatching.title)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .italic()
                            .bold()

                        Picker(selection: $model.selectedFilterMatching, label: Text(FilterMatching.title)) {
                            ForEach(FilterMatching.allCases, id: \.rawValue) { matching in
                                Text(matching.name)
                                    .font(.body)
                                    .tag(matching)
                            }
                        }
                        .pickerStyle(.segmented)

                        if self.model.filterType == FilterType.deny {

                            Spacer()

                            Text(DenyFolderType.title)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .italic()
                                .bold()

                            Picker(selection: $model.selectedDenyFolderType, label: Text(DenyFolderType.title)) {
                                ForEach(DenyFolderType.allCases, id: \.rawValue) { folder in
                                    Text(folder.name)
                                        .font(.body)
                                        .tag(folder)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        Spacer()

                        Text(FilterTarget.title)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .italic()
                            .bold()

                        Picker(selection: $model.selectedFilterTarget, label: Text(FilterTarget.title)) {
                            ForEach(FilterTarget.allCases, id: \.rawValue) { target in
                                Text(target.name)
                                    .font(.body)
                                    .tag(target)
                            }
                        }
                        .pickerStyle(.segmented)

                        if self.model.selectedFilterMatching != .regex {
                            Spacer()

                            Text(FilterCase.title)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .italic()
                                .bold()

                            Picker(selection: $model.selectedFilterCase, label: Text(FilterCase.title)) {
                                ForEach(FilterCase.allCases, id: \.rawValue) { filterCase in
                                    Text(filterCase.name)
                                        .font(.body)
                                        .tag(filterCase)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                    }

                    Button {
                        withAnimation {
                            self.model.isExpanded.toggle()
                        }
                    } label: {
                        HStack (alignment: .center, spacing: 8) {
                            Spacer()

                            Text(self.model.isExpanded ? "addFilter_less"~ : "addFilter_more"~)
                                .font(.footnote)
                                .bold()
                                .foregroundColor(.primary)

                            Image(systemName: "arrowtriangle.down.circle")
                                .font(.caption)
                                .rotationEffect(.degrees(reduceMotion ? 0 : (self.model.isExpanded ? 180 : 0)))
                                .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: self.model.isExpanded)
                            
                            Spacer()
                        }
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier(TestIdentifier.expandButton.rawValue)
                    .accessibilityLabel(self.model.isExpanded ? "addFilter_less"~ : "addFilter_more"~)
                    .accessibilityHint("a11y_addFilter_expandHint"~)
                    
                    Button {
                        withAnimation {
                            self.model.addFilter()
                            dismiss()
                        }
                    } label: {
                        Text("addFilter_add"~)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FilledButton())
                    .accessibilityIdentifier(TestIdentifier.addFilteraddFilterButton.rawValue)
                    .disabled(self.model.filterText.count < kMinimumFilterLength || self.model.isDuplicateFilter || self.model.isInvalidRegex)
                    .contentShape(Rectangle())
                } // VStack
                .padding(.horizontal, 16)
                .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: self.model.selectedFilterMatching)
                .navigationTitle(self.model.title)
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
            } // ScrollView
            
            Spacer()
                .padding()
        } // NavigationView
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                focusedField = .text
            }
        }
    }
}


//MARK: - ViewModel -
extension AddFilterView {

    enum Field: Int, Hashable {
        case text, regexTest
    }

    enum RegexTestResult {
        case match, noMatch, invalidPattern, empty
    }
    
    class ViewModel: BaseViewModel, ObservableObject, Identifiable {
        let id = UUID()
        @Published private(set) var isAllUnknownFilteringOn: Bool
        @Published private(set) var title: String
        @Published private(set) var filterType: FilterType
        @Published var filterText = ""
        @Published var selectedDenyFolderType = DenyFolderType.junk
        @Published var selectedFilterTarget = FilterTarget.all
        @Published var selectedFilterMatching = FilterMatching.contains
        @Published var selectedFilterCase = FilterCase.caseInsensitive
        @Published var regexTestText = ""
        @Published var isExpanded: Bool {
            didSet {
                self.appManager.defaultsManager.isExpandedAddFilter = self.isExpanded
            }
        }
        
        private var didAddFilter = false
        private var onAdded: ((Filter) -> Void)?

        init(filterType: FilterType,
             onAdded: ((Filter) -> Void)? = nil,
             appManager: AppManagerProtocol = AppManager.shared) {
            self.onAdded = onAdded
            
            self.filterType = filterType
            
            switch filterType {
            case .deny:
                self.title = "addFilter_addFilter_deny"~
            case .allow:
                self.title = "addFilter_addFilter_allow"~
            case .denyLanguage:
                self.title = "addFilter_addFilter_deny"~
            }
            
            let isAllUnknownFilteringOn = appManager.automaticFilterManager.automaticRuleState(for: .allUnknown)
            self.isAllUnknownFilteringOn = isAllUnknownFilteringOn
            self.isExpanded = appManager.defaultsManager.isExpandedAddFilter
            
            super.init(appManager: appManager)
        }
        
        var isDuplicateFilter: Bool {
            return !self.didAddFilter && self.appManager.persistanceManager.isDuplicateFilter(text: self.filterText,
                                                                                              filterTarget: self.selectedFilterTarget,
                                                                                              filterMatching: self.selectedFilterMatching,
                                                                                              filterCase: self.selectedFilterCase)
        }

        var isInvalidRegex: Bool {
            guard selectedFilterMatching == .regex, !filterText.isEmpty else { return false }
            return (try? Regex(filterText)) == nil
        }

        var regexTestResult: RegexTestResult {
            guard selectedFilterMatching == .regex else { return .empty }
            guard !regexTestText.isEmpty else { return .empty }
            guard let regex = try? Regex(filterText) else { return .invalidPattern }
            return regexTestText.contains(regex) ? .match : .noMatch
        }

        func addFilter() {
            self.didAddFilter = true
            let filter = self.appManager.persistanceManager.addFilter(text: self.filterText,
                                                                      type: self.filterType,
                                                                      denyFolder: self.selectedDenyFolderType,
                                                                      filterTarget: self.selectedFilterTarget,
                                                                      filterMatching: self.selectedFilterMatching,
                                                                      filterCase: self.selectedFilterCase)
            if let filter {
                self.onAdded?(filter)
            }
        }
    }
}


//MARK: - Preview -
struct AddFilterView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AddFilterView(model: AddFilterView.ViewModel(filterType: .deny, appManager: AppManager.previews))
        }
    }
}
