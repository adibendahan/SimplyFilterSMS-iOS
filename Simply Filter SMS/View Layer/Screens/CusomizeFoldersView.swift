//
//  CusomizeFoldersView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 30/09/2022.
//

import SwiftUI
import IdentityLookup

struct CusomizeFoldersView: View {
    @State var selected = Set<DenyFolderType>()
    @State private var animate = false
    let maxSelectionCount = 5
    @Environment(\.dismiss)
    var dismiss
    
    var body: some View {
        NavigationView {
            ZStack (alignment: .bottom) {
                List(selection: $selected) {
                    ForEach(DenyFolderType.allCases.sorted(by: { $0.rawValue > $1.rawValue }), id: \.self) { denyFolder in
                        let subFolders = DenyFolderType.allCases.filter({ $0.parent == denyFolder }).sorted(by: { $0.name < $1.name })
                        
                        if subFolders.count > 0 {
                            Section(header: Text(denyFolder.name)) {
                                ForEach(subFolders, id: \.self) { folder in
                                    HStack {
                                        Text(folder.name)
                                        Spacer()
                                        Image(systemName: folder.iconName)
                                    }
                                    .listRowBackground(Color(UIColor.systemBackground))
                                }
                            }
                        }
                    }
                }
                .environment(\.editMode, Binding.constant(.active))
                .onChange(of: selected) { selected in
                    if (selected.count > maxSelectionCount  && !animate) || (selected.count <= maxSelectionCount && animate) {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            animate.toggle()
                        }
                    }
                }
                
                VStack {
                    Button {
                        let selectedFolders = self.selected.map({ $0.rawValue })
                        var d = AppManager.shared.defaultsManager
                        d.selectedSubFolders = selectedFolders
                        dismiss()
                    } label: {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FilledButton())
                    .disabled(animate ? true : false)
                    .contentShape(Rectangle())
                    .padding()
                }
                .background(.ultraThinMaterial)
                
                
                Text("Maximum 5 folders allowed")
                    .foregroundColor(.red)
                    .font(.caption)
                    .opacity(animate ? 1.0 : 0.0)
                    .padding(.top, -84)
            }
            .navigationTitle("Folders")
        }
        .onAppear(perform: {
            self.selected = Set(AppManager.shared.defaultsManager.selectedSubFolders.map({ DenyFolderType(rawValue: $0)! }))
        })
    }
}


struct CusomizeFoldersView_Previews: PreviewProvider {
    static var previews: some View {
        CusomizeFoldersView()
    }
}
