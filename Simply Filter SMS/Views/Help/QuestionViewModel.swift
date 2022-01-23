//
//  QuestionViewModel.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import SwiftUI

class QuestionViewModel: ObservableObject, Identifiable {
    let id: UUID = UUID()
    @Published var text: String
    @Published var answer: String
    @Published var action: QuestionAction
    @Published var onAction: (() -> ())? = nil
    
    init(text: String, answer: String, action: QuestionAction = .none, onAction: (() -> ())? = nil) {
        self.text = text
        self.answer = answer
        self.action = action
        self.onAction = onAction
    }
}

enum QuestionAction {
    case none, activateFilters
}
