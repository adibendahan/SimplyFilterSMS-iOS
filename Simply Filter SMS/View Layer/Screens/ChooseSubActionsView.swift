//
//  CusomizeFoldersView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 30/09/2022.
//

import SwiftUI
import IdentityLookup

//MARK: - View -
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
                        Text("chooseSubActions_save"~)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FilledButton())
                    .disabled(model.animate ? true : false)
                    .contentShape(Rectangle())
                    .padding()
                    .disabled(self.model.initialSelection == self.model.selected)
                }
                .background(.ultraThinMaterial)
                
                Text("chooseSubActions_max_folders"~)
                    .foregroundColor(.red)
                    .font(.caption)
                    .opacity(model.animate ? 1.0 : 0.0)
                    .padding(.top, -84)
            }
            .navigationTitle("chooseSubActions_title"~)
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
            
            Button("chooseSubActions_settings"~) {
                self.model.saveChangesAndRedirectToSettings()
                dismiss()
            }
            
            Button("chooseSubActions_how"~) {
                dismiss()
                self.model.sheetCoordinator?.onDismiss?()
            }
            
            Button("enableExtension_ready_cancel"~, role: .cancel) { }
        } message: { details in
            Text(details.message)
        }
    }
}

//MARK: - ViewModel -
extension ChooseSubActionsView {
    class ViewModel: BaseViewModel, ObservableObject {
        
        struct SaveAlertDetails: Identifiable {
            let title: String
            let message: String
            let id = UUID()
        }
        
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
        @Published var details: SaveAlertDetails = SaveAlertDetails(title: "chooseSubActions_alert_title"~,
                                                                    message: "chooseSubActions_alert_body"~)
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

//MARK: - Preview -
struct ChooseSubActionsView_Previews: PreviewProvider {
    static var previews: some View {
        ChooseSubActionsView(model: ChooseSubActionsView.ViewModel(appManager: AppManager.previews))
    }
}
