//
//  AppManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation

class AppManager: AppManagerProtocol {
    static let shared: AppManagerProtocol = AppManager()
    
    var persistanceManager: PersistanceManagerProtocol
    var defaultsManager: DefaultsManagerProtocol
    var automaticFiltersManager: AutomaticFilterManagerProtocol
    
    lazy var previewsPersistanceManager: PersistanceManagerProtocol = {
        let result = PersistanceManager(inMemory: true)
        result.loadDebugData()
        return result
    }()
    
    init() {
        let persistanceManager = PersistanceManager()
        let defaultsManager = DefaultsManager()
        
        self.persistanceManager = persistanceManager
        self.defaultsManager = defaultsManager
        self.automaticFiltersManager = AutomaticFilterManager(persistanceManager: persistanceManager)
    }
    
    func getFrequentlyAskedQuestions() -> [QuestionViewModel] {
        return [QuestionViewModel(text: "faq_question_0"~, answer: "faq_answer_0"~, action: .activateFilters),
                QuestionViewModel(text: "faq_question_1"~, answer: "faq_answer_1"~),
                QuestionViewModel(text: "faq_question_2"~, answer: "faq_answer_2"~),
                QuestionViewModel(text: "faq_question_3"~, answer: "faq_answer_3"~),
                QuestionViewModel(text: "faq_question_4"~, answer: "faq_answer_4"~),
                QuestionViewModel(text: "faq_question_5"~, answer: "faq_answer_5"~),
                QuestionViewModel(text: "help_automaticFiltering_question"~, answer: "help_automaticFiltering"~)]
    }
}
