//
//  FadingTextView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 01/02/2022.
//

import SwiftUI

struct FadingTextView: View {
    
    class Model: ObservableObject {
        @Published var duration: Double
        @Published var text: String
        
        init(text: String = "", duration: Double = 0.25) {
            self.text = text
            self.duration = duration
        }
    }
    
    @StateObject var model: FadingTextView.Model
    
    @State private var currentText: String? = nil
    @State private var isVisible: Bool = true
    
    var body: some View {
        Text(self.currentText ?? self.model.text)
            .opacity(self.isVisible ? 1 : 0)
            .animation(.linear(duration: self.model.duration), value: self.isVisible)
            .onReceive(self.model.$text, perform: updateText(_:))
    }
    
    private func withDuration(_ closure: @escaping () -> ()) {
        DispatchQueue.main.asyncAfter(deadline: .now() + (self.model.duration)) {
            closure()
        }
    }
    
    private func updateText(_: Any) {
        guard self.currentText != nil else {
            self.currentText = self.model.text
            self.withDuration {
                self.isVisible = true
            }
            return
        }
        
        guard self.currentText != self.model.text, self.currentText?.isEmpty == false else {
            self.currentText = self.model.text
            return
        }
        
        self.isVisible = false
        self.withDuration {
            self.currentText = self.model.text
            self.withDuration {
                self.isVisible = true
            }
        }
    }
}


struct FadingTextView_Previews: PreviewProvider {
    static var previews: some View {
        FadingTextView(model: FadingTextView.Model(text: "Hello, World!"))
    }
}
