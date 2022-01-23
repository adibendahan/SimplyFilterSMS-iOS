//
//  AppManager.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import Foundation

class AppManager: AppManagerProtocol {
    static let shared: AppManagerProtocol = AppManager()
    
    var persistanceManager: PersistanceManagerProtocol = PersistanceManager()
    var defaultsManager: DefaultsManagerProtocol = DefaultsManager()
}
