//
//  AddFilterView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 26/12/2021.
//

import SwiftUI

struct AddFilterView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) var dismiss
    
    @FocusState private var focusedField: Field?
    
    @State private var filterText = ""
    @State private var selectedFilterType = FilterType.deny
    @State private var selectedDenyFolderType = DenyFolderType.junk
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                VStack(alignment: .leading, spacing: 8) {
                    
                    Spacer()
                    Text("addFilter_text_caption"~)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .italic()
                        .bold()

                    TextField("addFilter_text"~, text: $filterText)
                        .focused($focusedField, equals: .text)
                    
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
                        
                            Picker(selection: $selectedDenyFolderType, label: Text("")) {
                                ForEach(DenyFolderType.allCases, id: \.rawValue) { folder in
                                    HStack {
                                        Image(systemName: folder.iconName)
                                        Text(folder.name)
                                            .font(.body)
                                    }
                                    .tag(folder)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: geometry.size.width-32, height: 32, alignment: .center)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Spacer()
                    
                    Button {
                        addFilter()
                        dismiss()
                    } label: {
                        Text("addFilter_add"~)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FilledButton())
                    .disabled(filterText.isEmpty)
                    .contentShape(Rectangle())
                    
                    Spacer()
                        .padding()
                }
                .frame(width: geometry.size.width-32, alignment: .center)
                .navigationTitle("addFilter_addFilter"~)
                .toolbar {
                    ToolbarItem {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .bold, design: .default))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                focusedField = .text
            }
        }
    }
    
    private func addFilter() {
        withAnimation {
            let newFilter = Filter(context: viewContext)
            newFilter.uuid = UUID()
            newFilter.filterType = self.selectedFilterType
            newFilter.denyFolderType = self.selectedDenyFolderType
            newFilter.text = self.filterText

            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

private enum Field: Int, Hashable {
    case text
}

struct AddFilterView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        return ZStack {
            AddFilterView().environment(\.managedObjectContext, context)
        }
    }
}
