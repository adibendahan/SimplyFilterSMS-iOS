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
    private var onEditingChanged: ((Bool) -> ())?
    private var onTextChange: ((String) -> ())?
    private var minimumCharacters: Int

    public init(_ text: Binding<String>,
                minimumCharacters: Int = 0,
                onCommit: (() -> ())? = nil,
                onEditingChanged: ((Bool) -> ())? = nil,
                onTextChange: ((String) -> ())? = nil) {

        self._text = text
        self.onCommit = onCommit
        self.onEditingChanged = onEditingChanged
        self.onTextChange = onTextChange
        self.minimumCharacters = minimumCharacters
    }

    @ViewBuilder
    public var body: some View {
        ZStack {
            Text(self.text)
                .opacity(self.editProcessGoing ? 0 : 1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityHidden(true)

            TextField(
                "",
                text: $newValue,
                onEditingChanged: { isEditing in
                    self.onEditingChanged?(isEditing)
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
            .accessibilityLabel(self.text)
            .onChange(of: newValue) { value in
                self.onTextChange?(value)
            }
        }
        .onTapGesture(count: 1, perform: {
            self.isFocused = true
            self.editProcessGoing = true
        })
        .onChange(of: isFocused) { focused in
            if focused && !editProcessGoing {
                editProcessGoing = true
            }
        }
    }
}
