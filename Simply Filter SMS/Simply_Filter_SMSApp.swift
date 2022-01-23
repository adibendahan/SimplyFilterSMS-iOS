//
//  Simply_Filter_SMSApp.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/12/2021.
//

import SwiftUI

@main
struct Simply_Filter_SMSApp: App {
    var body: some Scene {
        WindowGroup {
            let model = FilterListViewModel(persistanceManager: AppManager.shared.persistanceManager,
                                            defaultsManager: AppManager.shared.defaultsManager)
            FilterListView(model: model)
        }
    }
}
