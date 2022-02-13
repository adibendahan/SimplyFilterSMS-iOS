//
//  mock_AppManager.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 03/02/2022.
//

import Foundation
import XCTest
import OSLog
@testable import Simply_Filter_SMS

class mock_AppManager: AppManagerProtocol {
    
    
    static var logger: Logger = Logger(subsystem: "com.grizz.apps.dev.Simply-Filter-SMS", category: "tests")

    var persistanceManager: PersistanceManagerProtocol = mock_PersistanceManager()
    var defaultsManager: DefaultsManagerProtocol = mock_DefaultsManager()
    var automaticFilterManager: AutomaticFilterManagerProtocol = mock_AutomaticFilterManager()
    var messageEvaluationManager: MessageEvaluationManagerProtocol = mock_MessageEvaluationManager()
    var networkSyncManager: NetworkSyncManagerProtocol = mock_NetworkSyncManager()
    var amazonS3Service: AmazonS3ServiceProtocol = mock_AmazonS3Service()
    
    var getFrequentlyAskedQuestionsCounter = 0
    var getFrequentlyAskedQuestionsClosuer: (() -> ([QuestionView.ViewModel]))?
    
    func getFrequentlyAskedQuestions() -> [QuestionView.ViewModel] {
        return self.getFrequentlyAskedQuestionsClosuer?() ?? []
    }
    
    func resetCounters() {
        self.getFrequentlyAskedQuestionsCounter = 0
    }
}
