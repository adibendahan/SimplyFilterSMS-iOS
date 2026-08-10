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
    @State private var newValue: String
    @State private var editProcessGoing = false

    private var onCommit: (() -> ())?
    private var onEditingChanged: ((Bool) -> ())?
    private var onTextChange: ((String) -> ())?
    private var minimumCharacters: Int
    private var attributedText: ((String) -> AttributedString)?

    public init(_ text: Binding<String>,
                minimumCharacters: Int = 0,
                attributedText: ((String) -> AttributedString)? = nil,
                onCommit: (() -> ())? = nil,
                onEditingChanged: ((Bool) -> ())? = nil,
                onTextChange: ((String) -> ())? = nil) {

        self._text = text
        self._newValue = State(initialValue: text.wrappedValue)
        self.onCommit = onCommit
        self.onEditingChanged = onEditingChanged
        self.onTextChange = onTextChange
        self.minimumCharacters = minimumCharacters
        self.attributedText = attributedText
    }

    @ViewBuilder
    public var body: some View {
        ZStack(alignment: .leading) {
            if let attributedText {
                let displayText = editProcessGoing ? newValue : text
                Text(displayText.isEmpty ? AttributedString("") : attributedText(displayText))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)
            } else {
                Text(self.text)
                    .opacity(self.editProcessGoing ? 0 : 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)
            }

            // Keep the TextField hittable at full width when idle (tap-to-edit), but
            // opacity 0 so it does not paint a second RTL copy over the display Text.
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
            .foregroundColor(attributedText != nil ? .clear : .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .focused($isFocused)
            .accessibilityLabel(self.text)
            .onChange(of: newValue) { value in
                self.onTextChange?(value)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(count: 1, perform: {
            self.beginEditing()
        })
        .onChange(of: isFocused) { focused in
            if focused && !editProcessGoing {
                beginEditing()
            }
        }
    }

    private func beginEditing() {
        newValue = text
        isFocused = true
        editProcessGoing = true
    }
}
