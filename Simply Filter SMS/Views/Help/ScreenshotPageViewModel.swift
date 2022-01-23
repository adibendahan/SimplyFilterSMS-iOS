//
//  ScreenshotPageViewModel.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 24/01/2022.
//

import SwiftUI

class ScreenshotPageViewModel: ObservableObject {

    @Published var title: String
    @Published var text: String
    @Published var image: String
    @Published var confirmText: String
    @Published var onConfirm: (() -> ())? = nil
    
    init(title: String,
         text: String,
         image: String,
         confirmText: String,
         onConfirm: (() -> ())? = nil) {
        
        self.title = title
        self.text = text
        self.image = image
        self.confirmText = confirmText
        self.onConfirm = onConfirm
    }
}
