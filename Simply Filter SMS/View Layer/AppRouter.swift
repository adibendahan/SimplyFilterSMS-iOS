//
//  AppRouter.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 02/02/2022.
//

import Foundation
import SwiftUI
import MessageUI

enum RootScreen {
    case appHome, help
}

enum NavigationScreen: Hashable {
    case automaticBlocking
    case filterList(FilterType)
}

enum SheetScreen: Int, Identifiable {
    var id: Self { self }
    case about, help, enableExtension, testFilters, addLanguageFilter, addFilter
}

enum ModalFullScreen: Int, Identifiable {
    var id: Self { self }
    case enableExtension
}

class AppRouter: BaseViewModel, ObservableObject {
    
    private(set) var root: RootScreen
    
    @Published var navigationScreen: NavigationScreen? = nil
    @Published var sheetScreen: SheetScreen? = nil
    @Published var modalFullScreen: ModalFullScreen? = nil
    @Published var composeMailScreen: Bool = false
    
    
    init(root: RootScreen = .appHome,
         appManager: AppManagerProtocol = AppManager.shared) {
        
        self.root = root
        super.init(appManager: appManager)
    }

    @ViewBuilder func languageListView(mode: LanguageListView.Mode) -> some View {
        LanguageListView(router: self, model: LanguageListView.ViewModel(mode: mode, appManager: self.appManager))
    }
    
    @ViewBuilder func filterListView(for filterType: FilterType) -> some View {
        FilterListView(router: self, model: FilterListView.ViewModel(filterType: filterType, appManager: self.appManager))
    }
    
    @ViewBuilder func aboutView() -> some View {
        AboutView(router: self)
    }
    
    @ViewBuilder func helpView() -> some View {
        if self.root == .help {
            HelpView(router: self, model: HelpView.ViewModel(appManager: self.appManager))
        }
        else {
            AppRouterView(router: AppRouter(root: .help, appManager: self.appManager))
        }
    }
    
    @ViewBuilder func appHomeView() -> some View {
        if self.root == .appHome {
            AppHomeView(router: self, model: AppHomeView.ViewModel(appManager: self.appManager))
        }
        else {
            AppRouterView(router: AppRouter(root: .appHome, appManager: self.appManager))
        }
    }
    
    @ViewBuilder func testFiltersView() -> some View {
        TestFiltersView(router: self, model: TestFiltersView.ViewModel(appManager: self.appManager))
    }
    
    @ViewBuilder func enableExtensionView(showWelcome: Bool) -> some View {
        EnableExtensionView(router: self, model: EnableExtensionView.ViewModel(showWelcome: showWelcome, appManager: self.appManager))
    }
    
    @ViewBuilder func addFilterView() -> some View {
        AddFilterView(router: self,
                      model: AddFilterView.ViewModel(appManager: self.appManager))
    }
}



struct AppRouterView: View {
    @ObservedObject var router: AppRouter
    @State var composeMailScreen: Bool = false
    @State var result: Result<MFMailComposeResult, Error>? = nil
    
    var body: some View {
        NavigationView {
            switch router.root {
            case .appHome:
                self.router.appHomeView()
            case .help:
                self.router.helpView()
            }
            
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .modifier(EmbeddedFooterView(onTap: { self.router.sheetScreen = .about }))
        .sheet(item: $router.sheetScreen) {  } content: { sheetScreen in
            switch (sheetScreen) {
            case .about:
                self.router.aboutView()
                
            case .help:
                self.router.helpView()
                
            case .testFilters:
                self.router.testFiltersView()
                
            case .enableExtension:
                self.router.enableExtensionView(showWelcome: false)
                
            case .addLanguageFilter:
                self.router.languageListView(mode: .blockLanguage)
                
            case .addFilter:
                self.router.addFilterView()

            }
        }
        .sheet(isPresented: $composeMailScreen) {  } content: {
            MailView(isShowing: $composeMailScreen, result: $result)
                            .edgesIgnoringSafeArea(.bottom)
        }
        .fullScreenCover(item: $router.modalFullScreen) { } content: { modalFullScreen in
            switch modalFullScreen {
            case .enableExtension:
                self.router.enableExtensionView(showWelcome: true)
            }
        }
        .onReceive(router.$composeMailScreen) { newValue in
            self.composeMailScreen = newValue
        }
    }
}
