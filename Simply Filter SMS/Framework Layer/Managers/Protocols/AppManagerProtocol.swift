//
//  AppManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation
import OSLog

protocol AppManagerProtocol {
    static var logger: Logger { get }
    
    var persistanceManager: PersistanceManagerProtocol { get }
    var defaultsManager: DefaultsManagerProtocol { get set }
    var automaticFiltersManager: AutomaticFilterManagerProtocol { get }
    var messageEvaluationManager: MessageEvaluationManagerProtocol { get }
    
    func getFrequentlyAskedQuestions() -> [QuestionView.Model]

    //MARK: Debug
    var previewsPersistanceManager: PersistanceManagerProtocol { get }
}
