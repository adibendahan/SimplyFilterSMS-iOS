//
//  AddFilterView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 26/12/2021.
//

import SwiftUI


//MARK: - View -
struct AddFilterView: View {
    
    @Environment(\.dismiss)
    var dismiss
    
    @ObservedObject var model: ViewModel
    @FocusState private var focusedField: Field?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {

                    Spacer()

                    HStack (alignment: .center) {
                        
                        TextField("addFilter_text"~, text: $model.filterText)
                            .focused($focusedField, equals: .text)
                        
                        if self.model.isDuplicateFilter {
                            HStack {
                                Image(systemName: "xmark.octagon")
                                    .foregroundColor(.red.opacity(0.8))
                                
                                Text("addFilter_duplicate"~)
                                    .font(.footnote)
                                    .foregroundColor(.red)
                            }
                            .padding(EdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4))
                            .background(Color.red.opacity(0.1))
                            .containerShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                    }
                    
                    if self.model.isExpanded {
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
                                .rotationEffect(.degrees(self.model.isExpanded ? 180 : 0))
                            
                            Spacer()
                        }
                    }
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    
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
                    .disabled(self.model.filterText.count < kMinimumFilterLength || self.model.isDuplicateFilter)
                    .contentShape(Rectangle())
                } // VStack
                .padding(.horizontal, 16)
                .navigationTitle(self.model.title)
                .toolbar {
                    ToolbarItem {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.secondary)
                        }
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
        case text
    }
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published private(set) var isAllUnknownFilteringOn: Bool
        @Published private(set) var title: String
        @Published private(set) var filterType: FilterType
        @Published var filterText = ""
        @Published var selectedDenyFolderType = DenyFolderType.junk
        @Published var selectedFilterTarget = FilterTarget.all
        @Published var selectedFilterMatching = FilterMatching.contains
        @Published var selectedFilterCase = FilterCase.caseInsensitive
        @Published var isExpanded: Bool {
            didSet {
                self.appManager.defaultsManager.isExpandedAddFilter = self.isExpanded
            }
        }
        
        private var didAddFilter = false
        
        init(filterType: FilterType,
                      appManager: AppManagerProtocol = AppManager.shared) {
            
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
        
        func addFilter() {
            self.didAddFilter = true
            self.appManager.persistanceManager.addFilter(text: self.filterText,
                                                         type: self.filterType,
                                                         denyFolder: self.selectedDenyFolderType,
                                                         filterTarget: self.selectedFilterTarget,
                                                         filterMatching: self.selectedFilterMatching,
                                                         filterCase: self.selectedFilterCase)
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
