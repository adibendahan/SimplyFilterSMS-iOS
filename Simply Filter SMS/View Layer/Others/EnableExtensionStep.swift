//
//  EnableExtensionStep.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 07/03/2026.
//

import SwiftUI

enum EnableExtensionStep: CaseIterable, Hashable, EnableExtensionStepProtocol {
    case settings
    case messages
    case unknownSenders
    case screenUnknownSenders
    case filterSpam
    case textMessageFilter

    var stepNumber: Int {
        switch self {
        case .settings:
            return 1
        case .messages:
            return 2
        case .unknownSenders:
            return 3
        case .screenUnknownSenders:
            return 4
        case .filterSpam:
            return 5
        case .textMessageFilter:
            return 6
        }
    }

    var symbolName: String? {
        switch self {
        case .settings:
            return "gearshape.fill"
        case .messages:
            return "message.fill"
        default:
            return nil
        }
    }

    var symbolColor: Color? {
        switch self {
        case .settings:
            return .gray
        case .messages:
            return .green
        default:
            return nil
        }
    }

    var showsAppIcon: Bool {
        self == .textMessageFilter
    }

    var isToggle: Bool {
        self == .screenUnknownSenders || self == .filterSpam
    }

    var isLast: Bool {
        self == .textMessageFilter
    }

    var title: String {
        switch self {
        case .settings:
            return "enableExtension_step1_title"~
        case .messages:
            return "enableExtension_step2_title"~
        case .unknownSenders:
            return "enableExtension_step3_title"~
        case .screenUnknownSenders:
            return "enableExtension_step4_title"~
        case .filterSpam:
            return "enableExtension_step5_title"~
        case .textMessageFilter:
            return "enableExtension_step6_title"~
        }
    }

    var description: String {
        switch self {
        case .settings:
            return "enableExtension_step1_desc"~
        case .messages:
            return "enableExtension_step2_desc"~
        case .unknownSenders:
            return "enableExtension_step3_desc"~
        case .screenUnknownSenders:
            return "enableExtension_step4_desc"~
        case .filterSpam:
            return "enableExtension_step5_desc"~
        case .textMessageFilter:
            return "enableExtension_step6_desc"~
        }
    }
}
