//
//  ScreenshotPageViewModel.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 24/01/2022.
//

import SwiftUI

class ScreenshotPageViewModel: ObservableObject {
    
    private var id = UUID()
    
    @Published var title: String
    @Published var text: String
    @Published var image: String
    @Published var confirmText: String
    @Published var confirmAction: EnableExtensionView.PageCoordinator.Action
    
    init(title: String,
         text: String,
         image: String,
         confirmText: String,
         confirmAction: EnableExtensionView.PageCoordinator.Action) {
        
        self.title = title
        self.text = text
        self.image = image
        self.confirmText = confirmText
        self.confirmAction = confirmAction
    }
}

extension ScreenshotPageViewModel: Hashable {
    static func == (lhs: ScreenshotPageViewModel, rhs: ScreenshotPageViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
