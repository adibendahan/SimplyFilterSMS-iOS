//
//  EditableText.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 04/06/2022.
//

import SwiftUI

struct EditableText: View {

    private enum EndReason {
        case onCommit
        case onEditingChanged
        case focusChanged

        var logDescription: String {
            switch self {
            case .onCommit: return "onCommit"
            case .onEditingChanged: return "onEditingChanged(false)"
            case .focusChanged: return "focusChanged"
            }
        }
    }

    @Binding private var text: String
    private let focusID: UUID
    private var focusedID: FocusState<UUID?>.Binding

    @State private var newValue: String
    @State private var sessionActive = false

    private var onCommit: (() -> ())?
    private var onEditingChanged: ((Bool) -> ())?
    private var onTextChange: ((String) -> ())?
    private var minimumCharacters: Int
    private var attributedText: ((String) -> AttributedString)?

    public init(_ text: Binding<String>,
                focusID: UUID,
                focusedID: FocusState<UUID?>.Binding,
                minimumCharacters: Int = 0,
                attributedText: ((String) -> AttributedString)? = nil,
                onCommit: (() -> ())? = nil,
                onEditingChanged: ((Bool) -> ())? = nil,
                onTextChange: ((String) -> ())? = nil) {

        self._text = text
        self.focusID = focusID
        self.focusedID = focusedID
        self._newValue = State(initialValue: text.wrappedValue)
        self.onCommit = onCommit
        self.onEditingChanged = onEditingChanged
        self.onTextChange = onTextChange
        self.minimumCharacters = minimumCharacters
        self.attributedText = attributedText
    }

    private var isFocused: Bool {
        focusedID.wrappedValue == focusID
    }

    private var isEditorVisible: Bool {
        sessionActive || isFocused
    }

    @ViewBuilder
    public var body: some View {
        ZStack(alignment: .leading) {
            if let attributedText {
                let displayText = isEditorVisible ? newValue : text
                Text(displayText.isEmpty ? AttributedString("") : attributedText(displayText))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)
            } else {
                Text(self.text)
                    .opacity(isEditorVisible ? 0 : 1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)
            }

            TextField(
                "",
                text: $newValue,
                onEditingChanged: { isEditing in
                    AppManager.logger.debug("EditableText.onEditingChanged — isEditing: \(isEditing, privacy: .public), sessionActive: \(sessionActive, privacy: .public)")
                    if isEditing {
                        if !sessionActive {
                            beginEditing()
                        }
                    } else {
                        finishEditingIfNeeded(reason: .onEditingChanged)
                    }
                },
                onCommit: {
                    AppManager.logger.debug("EditableText.onCommit — sessionActive: \(sessionActive, privacy: .public)")
                    finishEditingIfNeeded(reason: .onCommit)
                })
            .opacity(isEditorVisible ? 1 : 0)
            .foregroundColor(attributedText != nil ? .clear : .primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .focused(focusedID, equals: focusID)
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
        .onChange(of: focusedID.wrappedValue) { newFocus in
            if newFocus == focusID {
                if !sessionActive {
                    beginEditing()
                }
            } else if sessionActive {
                finishEditingIfNeeded(reason: .focusChanged)
            }
        }
    }

    private func beginEditing() {
        guard !sessionActive else {
            focusedID.wrappedValue = focusID
            return
        }

        newValue = text
        sessionActive = true
        focusedID.wrappedValue = focusID
        onEditingChanged?(true)
        AppManager.logger.debug("EditableText.beginEditing — sessionActive: true")
    }

    private func finishEditingIfNeeded(reason: EndReason) {
        guard sessionActive else {
            AppManager.logger.debug("EditableText — finish ignored from \(reason.logDescription, privacy: .public) (no active session)")
            return
        }

        sessionActive = false

        let shouldCommit = minimumCharacters == 0 || newValue.count >= minimumCharacters
        if shouldCommit {
            text = newValue
        } else {
            newValue = text
        }

        let commit = shouldCommit ? onCommit : nil
        let editingChanged = onEditingChanged
        let focus = focusedID
        let id = focusID
        let reasonDescription = reason.logDescription

        DispatchQueue.main.async {
            if focus.wrappedValue == id {
                focus.wrappedValue = nil
            }
            editingChanged?(false)

            if let commit {
                AppManager.logger.debug("EditableText — invoking onCommit from \(reasonDescription, privacy: .public)")
                commit()
            } else {
                AppManager.logger.debug("EditableText — skipped onCommit from \(reasonDescription, privacy: .public) (below minimumCharacters)")
            }
        }
    }
}
