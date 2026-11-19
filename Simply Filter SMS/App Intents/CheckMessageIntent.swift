//
//  CheckMessageIntent.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/11/2026.
//

import AppIntents
import IdentityLookup

struct CheckMessageIntent: AppIntent {
    static let title: LocalizedStringResource = "siri_checkMessage_title"
    static let description = IntentDescription("siri_checkMessage_description")

    @Parameter(title: "siri_checkMessage_message",
               requestValueDialog: IntentDialog("siri_checkMessage_messagePrompt"))
    var message: String

    @Parameter(title: "siri_checkMessage_sender")
    var sender: String?

    static var parameterSummary: some ParameterSummary {
        Summary("siri_checkMessage_summary \(\.$message)") {
            \.$sender
        }
    }


    //MARK: - Public API -
    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let evaluator = SimplyFilterSMSShortcuts.appManager.messageEvaluationManager
        let sender = self.sender?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let result: MessageEvaluationResult

        if sender.isEmpty {
            result = evaluator.evaluateMessage(body: self.message)
        }
        else {
            result = evaluator.evaluateMessage(body: self.message, sender: sender)
        }
        Log.debug("siri check message, hasSender: \(!sender.isEmpty) → \(result.action.logName)")

        let reply = Self.reply(for: result)
        return .result(dialog: IntentDialog(stringLiteral: reply))
    }


    static func reply(for result: MessageEvaluationResult) -> String {
        let verdict = Self.verdict(for: result.action)
        let reply: String
        if result.match.value != nil, let caption = result.match.caption {
            reply = "\(verdict) \(caption)"
        }
        else {
            reply = verdict
        }
        return reply
    }


    //MARK: - Private -
    private static func verdict(for action: ILMessageFilterAction) -> String {
        switch action {
        case .junk, .filter:
            return String(format: "siri_checkMessage_folder"~, "addFilter_folder_junk"~)
        case .promotion:
            return String(format: "siri_checkMessage_folder"~, "addFilter_folder_promotions"~)
        case .transaction:
            return String(format: "siri_checkMessage_folder"~, "addFilter_folder_transactions"~)
        case .none, .allow:
            return "siri_checkMessage_inbox"~
        @unknown default:
            return "siri_checkMessage_inbox"~
        }
    }
}
