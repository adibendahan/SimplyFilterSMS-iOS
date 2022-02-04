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
    
    @StateObject var router: AppRouter
    @StateObject var model: ViewModel
    @FocusState private var focusedField: Field?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    let isDuplicate = self.model.isDuplicateFilter(text: self.model.filterText)
                    
                    Spacer()
                    
                    Text("addFilter_text_caption"~)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .italic()
                        .bold()
                    
                    HStack (alignment: .center) {
                        
                        TextField("addFilter_text"~, text: $model.filterText)
                            .focused($focusedField, equals: .text)
                        
                        if isDuplicate {
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
                    
                    Spacer()
                    
                    Text("addFilter_type_caption"~)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .italic()
                        .bold()
                    
                    Picker("addFilter_type"~, selection: $model.selectedFilterType.animation()) {
                        
                        if !self.model.isAllUnknownFilteringOn {
                            Text("general_deny"~)
                                .tag(FilterType.deny)
                        }
                        
                        Text("general_allow"~)
                            .tag(FilterType.allow)
                    }
                    .pickerStyle(.segmented)
                    
                    if self.model.selectedFilterType == FilterType.deny {
                        Spacer()
                        
                        Text("addFilter_folder_caption"~)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .italic()
                            .bold()
                        
                        Picker(selection: $model.selectedDenyFolderType, label: Text("addFilter_folder_caption"~)) {
                            ForEach(DenyFolderType.allCases, id: \.rawValue) { folder in
                                Text(folder.name)
                                    .font(.body)
                                    .tag(folder)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            self.model.addFilter(text: self.model.filterText,
                                                 type: self.model.selectedFilterType,
                                                 denyFolder: self.model.selectedDenyFolderType)
                            dismiss()
                        }
                    } label: {
                        Text("addFilter_add"~)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FilledButton())
                    .disabled(self.model.filterText.count < kUpdateAutomaticFiltersMinDays || isDuplicate)
                    .contentShape(Rectangle())
                } // VStack
                .padding(.horizontal, 16)
                .navigationTitle("addFilter_addFilter"~)
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
        @Published var isAllUnknownFilteringOn: Bool
        @Published var filterText = ""
        @Published var selectedFilterType = FilterType.deny
        @Published var selectedDenyFolderType = DenyFolderType.junk
        private var didAddFilter = false
        
        override init(appManager: AppManagerProtocol = AppManager.shared) {
            let isAllUnknownFilteringOn = appManager.automaticFilterManager.automaticRuleState(for: .allUnknown)
            self.isAllUnknownFilteringOn = isAllUnknownFilteringOn
            self.selectedFilterType = isAllUnknownFilteringOn ? FilterType.allow : FilterType.deny
            
            super.init(appManager: appManager)
        }
        
        func isDuplicateFilter(text: String) -> Bool {
            return !self.didAddFilter && self.appManager.persistanceManager.isDuplicateFilter(text: text)
        }
        
        func addFilter(text: String, type: FilterType, denyFolder: DenyFolderType) {
            self.didAddFilter = true
            self.appManager.persistanceManager.addFilter(text: text, type: type, denyFolder: denyFolder)
        }
    }
}


//MARK: - Preview -
struct AddFilterView_Previews: PreviewProvider {
    static var previews: some View {
        return ZStack {
            AddFilterView(router: AppRouter(appManager: AppManager.previews()),
                model: AddFilterView.ViewModel(appManager: AppManager.previews()))
        }
    }
}
