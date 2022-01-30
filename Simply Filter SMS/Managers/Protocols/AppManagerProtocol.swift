//
//  AppManagerProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation

protocol AppManagerProtocol {
    var persistanceManager: PersistanceManagerProtocol { get }
    var defaultsManager: DefaultsManagerProtocol { get set }
    var automaticFiltersManager: AutomaticFilterManagerProtocol { get }
    var previewsPersistanceManager: PersistanceManagerProtocol { get }
    
    func getFrequentlyAskedQuestions() -> [QuestionViewModel]
}
