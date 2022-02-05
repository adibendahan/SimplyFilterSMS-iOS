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
            AppHomeView(model: AppHomeView.ViewModel(appManager: AppManager.shared))
        }
    }
}
