//
//  CusomizeFoldersView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 30/09/2022.
//

import SwiftUI
import IdentityLookup

struct ChooseSubActionsView: View {
    
    @Environment(\.dismiss)
    var dismiss
    
    @ObservedObject var model: ViewModel
    
    var body: some View {
        NavigationView {
            ZStack (alignment: .bottom) {
                List(selection: $model.selected) {
                    ForEach(DenyFolderType.allCases.sorted(by: { $0.rawValue > $1.rawValue }), id: \.self) { denyFolder in
                        let subFolders = DenyFolderType.allCases.filter({ $0.parent == denyFolder }).sorted(by: { $0.name < $1.name })
                        
                        if subFolders.count > 0 {
                            Section(header: Text(denyFolder.name)) {
                                ForEach(subFolders, id: \.self) { folder in
                                    HStack {
                                        Text(folder.name)
                                            .font(.body)
                                        Spacer()
                                        Image(systemName: folder.iconName)
                                            .foregroundColor(.accentColor)
                                    }
                                    .listRowBackground(Color(UIColor.systemBackground))
                                }
                            }
                        }
                    }
                }
                .environment(\.editMode, Binding.constant(.active))
                .onChange(of: model.selected) { selected in
                    if (selected.count > model.maxSelectionCount  && !model.animate) ||
                        (selected.count <= model.maxSelectionCount && model.animate) {
                        
                        withAnimation(.easeInOut(duration: 0.25)) {
                            model.animate.toggle()
                        }
                    }
                }
                
                VStack {
                    Button {
                        self.model.onSave()
                    } label: {
                        Text("Save")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FilledButton())
                    .disabled(model.animate ? true : false)
                    .contentShape(Rectangle())
                    .padding()
                    .disabled(self.model.initialSelection == self.model.selected)
                }
                .background(.ultraThinMaterial)
                
                
                Text("Maximum 5 folders allowed")
                    .foregroundColor(.red)
                    .font(.caption)
                    .opacity(model.animate ? 1.0 : 0.0)
                    .padding(.top, -84)
            }
            .navigationTitle("Choose Folders")
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
        }
        .onAppear(perform: {
            self.model.fetchChosenSubActions()
        })
        .alert(self.model.details.title,
               isPresented: $model.showingAlert,
               presenting: model.details) { details in

            Button("Go to Settings") {
                self.model.saveChangesAndRedirectToSettings()
                dismiss()
            }
            
            Button("Show me how") {
                dismiss()
                self.model.sheetCoordinator?.onDismiss?()
            }
            
            Button("Cancel", role: .cancel) { }
        } message: { details in
            Text(details.message)
        }
    }
    
    struct SaveAlertDetails: Identifiable {
        let title: String
        let message: String
        let id = UUID()
    }
    
    class ViewModel: BaseViewModel, ObservableObject {
        let maxSelectionCount = 5
        let initialSelection: Set<DenyFolderType>
        
        init(appManager: AppManagerProtocol = AppManager.shared, sheetCoordinator: SheetCoordinator? = nil) {
            self.initialSelection = Set(appManager.persistanceManager.fetchChosenSubActions())
            super.init(appManager: appManager)
            self.sheetCoordinator = sheetCoordinator
        }
        
        @Published var selected = Set<DenyFolderType>()
        @Published var animate = false
        @Published var showingAlert = false
        @Published var details: SaveAlertDetails = SaveAlertDetails(title: "Important Notice!", message: "To apply folder changes on Messages app you *MUST* disable and then re-enable Simply Filter SMS as your message filtering application.\n\nIf you fail to do so, message filtering might behave unexpectedly or fail completely.")
        @Published var sheetCoordinator: SheetCoordinator?

        func fetchChosenSubActions() {
            self.selected = Set(self.appManager.persistanceManager.fetchChosenSubActions())
        }

        func onSave() {
            self.showingAlert = true
        }
        
        func saveChangesAndRedirectToSettings() {
            let chosenSubActions = self.selected.map({ $0 })
            self.appManager.persistanceManager.updateChosenSubActions(chosenSubActions)
            
            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsURL)
            }
        }
    }
}


struct ChooseSubActionsView_Previews: PreviewProvider {
    static var previews: some View {
        ChooseSubActionsView(model: ChooseSubActionsView.ViewModel(appManager: AppManager.previews))
    }
}
