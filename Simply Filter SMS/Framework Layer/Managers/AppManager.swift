//
//  AppManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation
import OSLog
import Network

class AppManager: AppManagerProtocol {
    static let shared: AppManagerProtocol = AppManager()
    static let logger: Logger = Logger(subsystem: "com.grizz.apps.dev.Simply-Filter-SMS", category: "main")
    
    var persistanceManager: PersistanceManagerProtocol
    var defaultsManager: DefaultsManagerProtocol
    var automaticFilterManager: AutomaticFilterManagerProtocol
    var messageEvaluationManager: MessageEvaluationManagerProtocol
    var networkSyncManager: NetworkSyncManagerProtocol
    var amazonS3Service: AmazonS3ServiceProtocol
    
    init(inMemory: Bool = false) {
        let persistanceManager = PersistanceManager(inMemory: inMemory)
        let defaultsManager = DefaultsManager()
        let messageEvaluationManager = MessageEvaluationManager(container: persistanceManager.container)
        let networkSyncManager = NetworkSyncManager(persistanceManager: persistanceManager)
        let amazonS3Service = AmazonS3Service(networkSyncManager: networkSyncManager)
        
        messageEvaluationManager.setLogger(AppManager.logger)
        
        self.persistanceManager = persistanceManager
        self.defaultsManager = defaultsManager
        self.automaticFilterManager = AutomaticFilterManager(persistanceManager: persistanceManager,
                                                             amazonS3Service: amazonS3Service)
        self.messageEvaluationManager = messageEvaluationManager
        self.networkSyncManager = networkSyncManager
        self.amazonS3Service = amazonS3Service
    }
    
    func onAppLaunch() {
        let _ = self.defaultsManager.appAge // make sure it's initialized
        
        if let sessionAge = self.defaultsManager.sessionAge {
            if sessionAge.daysBetween(date: Date()) != 0 {
                self.onNewUserSession()
            }
        }
        else {
            self.onNewUserSession()
        }
    }
    
    func onNewUserSession() {
        self.defaultsManager.sessionCounter += 1
        self.defaultsManager.sessionAge = Date()
        
        if self.networkSyncManager.networkStatus == .online {
            self.automaticFilterManager.updateAutomaticFiltersIfNeeded()
        }
    }
    
    func getFrequentlyAskedQuestions() -> [QuestionView.ViewModel] {
        return [QuestionView.ViewModel(text: "faq_question_0"~, answer: "faq_answer_0"~, action: .activateFilters),
                QuestionView.ViewModel(text: "faq_question_1"~, answer: "faq_answer_1"~),
                QuestionView.ViewModel(text: "faq_question_2"~, answer: "faq_answer_2"~),
                QuestionView.ViewModel(text: "faq_question_3"~, answer: "faq_answer_3"~),
                QuestionView.ViewModel(text: "faq_question_4"~, answer: "faq_answer_4"~),
                QuestionView.ViewModel(text: "faq_question_5"~, answer: "faq_answer_5"~),
                QuestionView.ViewModel(text: "help_automaticFiltering_question"~, answer: "help_automaticFiltering"~)]
    }
    
    //MARK: - Previews -
    static private var inMemoryManager = AppManager(inMemory: true)
    static private var didLoadDebugData = false
    static var previews: AppManagerProtocol {
        if !didLoadDebugData {
            inMemoryManager.persistanceManager.loadDebugData()
            didLoadDebugData = true
        }
        
        return inMemoryManager
    }
}
