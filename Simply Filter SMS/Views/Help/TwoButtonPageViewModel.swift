//
//  TwoButtonPageViewModel.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 24/01/2022.
//

import SwiftUI

class TwoButtonPageViewModel: ObservableObject {
    
    private var id = UUID()
    
    @Published var title: String
    @Published var text: String
    @Published var confirmText: String
    @Published var confirmAction: EnableExtensionView.PageCoordinator.Action
    @Published var cancelText: String
    @Published var cancelAction: EnableExtensionView.PageCoordinator.Action
    @Published var image: String? = nil
    
    init(title: String,
         text: String,
         confirmText: String,
         confirmAction: EnableExtensionView.PageCoordinator.Action,
         cancelText: String,
         cancelAction: EnableExtensionView.PageCoordinator.Action,
         image: String? = nil) {
        
        self.title = title
        self.text = text
        self.confirmText = confirmText
        self.confirmAction = confirmAction
        self.cancelText = cancelText
        self.cancelAction = cancelAction
        self.image = image
    }
}

extension TwoButtonPageViewModel: Hashable {
    static func == (lhs: TwoButtonPageViewModel, rhs: TwoButtonPageViewModel) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
