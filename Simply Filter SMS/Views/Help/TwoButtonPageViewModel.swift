//
//  TwoButtonPageViewModel.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 24/01/2022.
//

import SwiftUI

class TwoButtonPageViewModel: ObservableObject {

    @Published var title: String
    @Published var text: String
    @Published var confirmText: String
    @Published var cancelText: String
    @Published var onConfirm: (() -> ())? = nil
    @Published var onCancel: (() -> ())? = nil
    @Published var image: String? = nil
    
    init(title: String,
         text: String,
         confirmText: String,
         cancelText: String,
         onConfirm: (() -> ())? = nil,
         onCancel: (() -> ())? = nil,
         image: String? = nil) {
        
        self.title = title
        self.text = text
        self.confirmText = confirmText
        self.cancelText = cancelText
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        self.image = image
    }
}
