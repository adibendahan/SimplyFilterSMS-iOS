//
//  AppManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation
import OSLog

class AppManager: AppManagerProtocol {
    static let shared: AppManagerProtocol = AppManager()
    static let logger: Logger = Logger(subsystem: "com.grizz.apps.dev.Simply-Filter-SMS", category: "main")
    static var previews: AppManagerProtocol = {
        let previewsAppManager = AppManager(inMemory: true)
        previewsAppManager.persistanceManager.loadDebugData()
        return previewsAppManager
    }()
    
    var persistanceManager: PersistanceManagerProtocol
    var defaultsManager: DefaultsManagerProtocol
    var automaticFilterManager: AutomaticFilterManagerProtocol
    var messageEvaluationManager: MessageEvaluationManagerProtocol
    
    init(inMemory: Bool = false) {
        let persistanceManager = PersistanceManager(inMemory: inMemory)
        let defaultsManager = DefaultsManager()
        let messageEvaluationManager = MessageEvaluationManager()
        
        messageEvaluationManager.setLogger(AppManager.logger)
        
        self.persistanceManager = persistanceManager
        self.defaultsManager = defaultsManager
        self.automaticFilterManager = AutomaticFilterManager(persistanceManager: persistanceManager)
        self.messageEvaluationManager = messageEvaluationManager
    }
    
    func getFrequentlyAskedQuestions() -> [QuestionView.Model] {
        return [QuestionView.Model(text: "faq_question_0"~, answer: "faq_answer_0"~, action: .activateFilters),
                QuestionView.Model(text: "faq_question_1"~, answer: "faq_answer_1"~),
                QuestionView.Model(text: "faq_question_2"~, answer: "faq_answer_2"~),
                QuestionView.Model(text: "faq_question_3"~, answer: "faq_answer_3"~),
                QuestionView.Model(text: "faq_question_4"~, answer: "faq_answer_4"~),
                QuestionView.Model(text: "faq_question_5"~, answer: "faq_answer_5"~),
                QuestionView.Model(text: "help_automaticFiltering_question"~, answer: "help_automaticFiltering"~)]
    }
}
