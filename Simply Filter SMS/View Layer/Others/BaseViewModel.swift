//
//  BaseViewModel.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 03/02/2022.
//

import Foundation

open class BaseViewModel {
    var appManager: AppManagerProtocol
    
    init(appManager: AppManagerProtocol = AppManager.shared) {
        self.appManager = appManager
    }
}
