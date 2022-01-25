//
//  HelpViewModel.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation

class HelpViewModel: ObservableObject {
    @Published var questions: [QuestionViewModel]
    @Published var title: String
    
    private let persistanceManager: PersistanceManagerProtocol
    
    init(persistanceManager: PersistanceManagerProtocol = AppManager.shared.persistanceManager) {
        self.persistanceManager = persistanceManager
        self.title = "filterList_menu_enableExtension"~
        self.questions = persistanceManager.getFrequentlyAskedQuestions()
    }
}
