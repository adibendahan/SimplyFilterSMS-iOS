//
//  AddFilterViewModel.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 28/01/2022.
//

import Foundation

class AddFilterViewModel: ObservableObject {
    @Published var isAllUnknownFilteringOn: Bool
    
    private var persistanceManager: PersistanceManagerProtocol
    
    init(isAllUnknownFilteringOn: Bool,
         persistanceManager: PersistanceManagerProtocol = AppManager.shared.persistanceManager) {
        self.persistanceManager = persistanceManager
        self.isAllUnknownFilteringOn = isAllUnknownFilteringOn
    }
    
    func isDuplicateFilter(text: String) -> Bool {
        return self.persistanceManager.isDuplicateFilter(text: text)
    }
    
    func addFilter(text: String, type: FilterType, denyFolder: DenyFolderType) {
        self.persistanceManager.addFilter(text: text, type: type, denyFolder: denyFolder)
    }
}
