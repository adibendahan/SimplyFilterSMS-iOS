//
//  BaseViewModel.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 03/02/2022.
//

import Foundation

open class BaseViewModel<S> {
    var appManager: S
    
    init(appManager: S) {
        self.appManager = appManager
    }
}
