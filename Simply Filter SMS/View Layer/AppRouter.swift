//
//  AppRouter.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 02/02/2022.
//

import Foundation
import SwiftUI

class AppRouter: BaseViewModel, ObservableObject {

    private(set) var screen: Screen
    
    @Published var navigationScreen: Screen? = nil
    @Published var sheetScreen: Screen? = nil
    @Published var modalFullScreen: Screen? = nil
    @Published var composeMailScreen: Bool = false
    
    init(screen: Screen = .appHome,
         appManager: AppManagerProtocol = AppManager.shared) {
        
        self.screen = screen
        super.init(appManager: appManager)
    }
    
    @ViewBuilder func make() -> some View {
        switch screen {
        case .appHome:
            AppHomeView(router: self,
                        model: AppHomeView.ViewModel(appManager: self.appManager))
            
        case .onboarding:
            EnableExtensionView(router: self,
                                model: EnableExtensionView.ViewModel(showWelcome: true, appManager: self.appManager))
            
        case .help:
            HelpView(router: self, model: HelpView.ViewModel(appManager: self.appManager))
            
        case .about:
            AboutView(router: self)
            
        case .enableExtension:
            EnableExtensionView(router: self,
                                model: EnableExtensionView.ViewModel(showWelcome: false, appManager: self.appManager))
            
        case .testFilters:
            TestFiltersView(router: self,
                            model: TestFiltersView.ViewModel(appManager: self.appManager))
            
        case .addLanguageFilter:
            LanguageListView(router: self,
                             model: LanguageListView.ViewModel(mode: .blockLanguage, appManager: self.appManager))
            
        case .addAllowFilter:
            AddFilterView(router: self,
                          model: AddFilterView.ViewModel(appManager: self.appManager))
            
        case .addDenyFilter:
            AddFilterView(router: self,
                          model: AddFilterView.ViewModel(appManager: self.appManager))
            
        case .automaticBlocking:
            LanguageListView(router: self,
                             model: LanguageListView.ViewModel(mode: .automaticBlocking, appManager: self.appManager))
            
        case .denyFilterList:
            FilterListView(router: self,
                           model: FilterListView.ViewModel(filterType: .deny, appManager: self.appManager))
            
        case .allowFilterList:
            FilterListView(router: self,
                           model: FilterListView.ViewModel(filterType: .allow, appManager: self.appManager))
            
        case .denyLanguageFilterList:
            FilterListView(router: self,
                           model: FilterListView.ViewModel(filterType: .denyLanguage, appManager: self.appManager))
        }
    }
    
    @ViewBuilder func make(screen: Screen) -> AppRouterView {
        let newRouter = AppRouter(screen: screen, appManager: self.appManager)
        AppRouterView(router: newRouter)
    }
}
