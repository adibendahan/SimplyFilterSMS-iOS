//
//  AddFilterView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 26/12/2021.
//

import SwiftUI

struct AddFilterView: View {

    @Environment(\.dismiss)
    var dismiss
    
    @FocusState private var focusedField: Field?
    
    @State var appManager: AppManagerProtocol = AppManager.shared
    @State private var filterText = ""
    @State private var selectedFilterType = FilterType.deny
    @State private var selectedDenyFolderType = DenyFolderType.junk
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        let isDuplicate = self.appManager.persistanceManager.isDuplicateFilter(text: filterText, type: selectedFilterType)
                        
                        Spacer()
                        
                        Text("addFilter_text_caption"~)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .italic()
                            .bold()
                        
                        HStack (alignment: .center) {
                            
                            TextField("addFilter_text"~, text: $filterText)
                                .focused($focusedField, equals: .text)
                            
                            if (isDuplicate) {
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
                        
                        Picker("addFilter_type"~, selection: $selectedFilterType.animation()) {
                            Text("general_deny"~)
                                .tag(FilterType.deny)
                            Text("general_allow"~)
                                .tag(FilterType.allow)
                        }
                        .pickerStyle(.segmented)
                        
                        if selectedFilterType == FilterType.deny {
                            Spacer()
                            
                            Text("addFilter_folder_caption"~)
                                .font(.footnote)
                                .foregroundColor(.secondary)
                                .italic()
                                .bold()
                            
                            Picker(selection: $selectedDenyFolderType, label: Text("addFilter_folder_caption"~)) {
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
                                self.appManager.persistanceManager.addFilter(text: self.filterText,
                                                                             type: self.selectedFilterType,
                                                                             denyFolder: self.selectedDenyFolderType)
                                dismiss()
                            }
                        } label: {
                            Text("addFilter_add"~)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(FilledButton())
                        .disabled(filterText.count < 3 || isDuplicate)
                        .contentShape(Rectangle())
                    } // VStack
                    .frame(width: geometry.size.width-32, alignment: .center)
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
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                focusedField = .text
            }
        }
    }
}

private enum Field: Int, Hashable {
    case text
}

struct AddFilterView_Previews: PreviewProvider {
    static var previews: some View {
        return ZStack {
            AddFilterView().environment(\.managedObjectContext, AppManager.shared.persistanceManager.preview.context)
        }
    }
}
