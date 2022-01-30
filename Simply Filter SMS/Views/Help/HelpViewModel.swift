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
    
    private let appManager: AppManagerProtocol
    
    init(appManager: AppManagerProtocol = AppManager.shared) {
        self.appManager = appManager
        self.title = "filterList_menu_enableExtension"~
        self.questions = appManager.getFrequentlyAskedQuestions()
    }
}
