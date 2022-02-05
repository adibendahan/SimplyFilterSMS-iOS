//
//  AppRouterView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 05/02/2022.
//

import SwiftUI
import MessageUI

struct AppRouterView: View {
    @ObservedObject var router: AppRouter
    @State var composeMailScreen: Bool = false
    @State var result: Result<MFMailComposeResult, Error>? = nil
    
    var body: some View {
        VStack {
            self.router.make()
        }
        .sheet(item: $router.sheetScreen) {
            self.router.sheetScreen = nil
        } content: { sheetScreen in
            self.router.make(screen: sheetScreen)
        }
        .sheet(isPresented: $composeMailScreen) {
            self.composeMailScreen = false
        } content: {
            MailView(isShowing: $composeMailScreen, result: $result)
                            .edgesIgnoringSafeArea(.bottom)
        }
        .fullScreenCover(item: $router.modalFullScreen) {
            self.router.modalFullScreen = nil
        } content: { modalFullScreen in
            self.router.make(screen: modalFullScreen)
        }
        .onReceive(router.$composeMailScreen) { newValue in
            self.composeMailScreen = newValue
        }
    }
}


struct AppRouterView_Previews: PreviewProvider {
    static var previews: some View {
        AppRouterView(router: AppRouter(screen: .appHome, appManager: AppManager.previews))
    }
}
