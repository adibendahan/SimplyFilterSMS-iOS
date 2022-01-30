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
    
    init(persistanceManager: PersistanceManagerProtocol = AppManager.shared.persistanceManager) {
        self.persistanceManager = persistanceManager
        self.isAllUnknownFilteringOn = persistanceManager.automaticRuleState(for: .allUnknown) == true
    }
    
    func isDuplicateFilter(text: String, type: FilterType) -> Bool {
        return self.persistanceManager.isDuplicateFilter(text: text, type: type)
    }
    
    func addFilter(text: String, type: FilterType, denyFolder: DenyFolderType) {
        self.persistanceManager.addFilter(text: text, type: type, denyFolder: denyFolder)
    }
}
