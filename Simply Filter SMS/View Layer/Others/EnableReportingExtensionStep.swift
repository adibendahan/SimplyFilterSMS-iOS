//
//  EnableReportingExtensionStep.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 25/03/2026.
//

import SwiftUI

enum EnableReportingExtensionStep: CaseIterable, Hashable, EnableExtensionStepProtocol {
    case settings
    case phone
    case smsCallReporting
    case simplyFilterSMS
    case longPressMessage
    case selectMessages
    case reportMessages

    var stepNumber: Int {
        switch self {
        case .settings:
            return 1
        case .phone:
            return 2
        case .smsCallReporting:
            return 3
        case .simplyFilterSMS:
            return 4
        case .longPressMessage:
            return 5
        case .selectMessages:
            return 6
        case .reportMessages:
            return 7
        }
    }

    var symbolName: String? {
        switch self {
        case .settings:
            return "gearshape.fill"
        case .phone:
            return "phone.fill"
        case .longPressMessage:
            return "message.fill"
        case .selectMessages:
            return "checkmark.circle.fill"
        case .reportMessages:
            return "paperplane.fill"
        default:
            return nil
        }
    }

    var symbolColor: Color? {
        switch self {
        case .settings:
            return .gray
        case .phone:
            return .green
        case .longPressMessage:
            return .green
        case .selectMessages:
            return .accentColor
        case .reportMessages:
            return .accentColor
        default:
            return nil
        }
    }

    var showsAppIcon: Bool {
        self == .simplyFilterSMS
    }

    var isToggle: Bool {
        false
    }

    var isLast: Bool {
        self == .reportMessages
    }

    var title: String {
        switch self {
        case .settings:
            return "enableReportingExtension_step1_title"~
        case .phone:
            return "enableReportingExtension_step2_title"~
        case .smsCallReporting:
            return "enableReportingExtension_step3_title"~
        case .simplyFilterSMS:
            return "enableReportingExtension_step4_title"~
        case .longPressMessage:
            return "enableReportingExtension_step5_title"~
        case .selectMessages:
            return "enableReportingExtension_step6_title"~
        case .reportMessages:
            return "enableReportingExtension_step7_title"~
        }
    }

    var description: String {
        switch self {
        case .settings:
            return "enableReportingExtension_step1_desc"~
        case .phone:
            return "enableReportingExtension_step2_desc"~
        case .smsCallReporting:
            return "enableReportingExtension_step3_desc"~
        case .simplyFilterSMS:
            return "enableReportingExtension_step4_desc"~
        case .longPressMessage:
            return "enableReportingExtension_step5_desc"~
        case .selectMessages:
            return "enableReportingExtension_step6_desc"~
        case .reportMessages:
            return "enableReportingExtension_step7_desc"~
        }
    }
}
