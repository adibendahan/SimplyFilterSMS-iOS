//
//  EditableText.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 04/06/2022.
//

import SwiftUI

struct EditableText: View {
    @Binding private var text: String
    @FocusState private var isFocused: Bool
    @State private var newValue: String = ""
    @State private var editProcessGoing = false {
        didSet {
            self.newValue = self.text
        }
    }
    
    private var onCommit: (() -> ())?
    private var minimumCharacters: Int
    
    public init(_ text: Binding<String>,
                minimumCharacters: Int = 0,
                onCommit: (() -> ())? = nil) {
        
        self._text = text
        self.onCommit = onCommit
        self.minimumCharacters = minimumCharacters
    }
    
    @ViewBuilder
    public var body: some View {
        ZStack {
            Text(self.text)
                .opacity(self.editProcessGoing ? 0 : 1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextField(
                "",
                text: $newValue,
                onEditingChanged: { isEditing in
                    if !isEditing {
                        if self.minimumCharacters > 0 && newValue.count >= self.minimumCharacters {
                            self.text = newValue
                            self.isFocused = false
                        }
                        self.editProcessGoing = false
                        onCommit?()
                    }
                },
                onCommit: {
                    if self.minimumCharacters > 0 && newValue.count >= self.minimumCharacters {
                        self.text = newValue
                        self.isFocused = false
                    }
                    self.editProcessGoing = false
                    onCommit?()
                })
            .opacity(self.editProcessGoing ? 1 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .focused($isFocused)
        }
        .onTapGesture(count: 1, perform: {
            self.isFocused = true
            self.editProcessGoing = true
        })
    }
}
