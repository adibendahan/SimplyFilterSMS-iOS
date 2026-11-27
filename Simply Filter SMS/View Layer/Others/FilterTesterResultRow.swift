//
//  FilterTesterResultRow.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/08/2026.
//

import SwiftUI
import IdentityLookup


//MARK: - View -
struct FilterTesterResultRow: View {

    let result: MessageEvaluationResult

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 20

    var body: some View {
        AdaptiveRow {
            Image(systemName: style.icon)
                .foregroundColor(style.color)
                .frame(width: iconSize, alignment: .center)
                .accessibilityHidden(true)
        } content: {
            VStack(alignment: .leading, spacing: 2) {
                Text(style.title)
                    .font(.headline)
                    .foregroundColor(style.color)
                    .fixedSize(horizontal: false, vertical: true)

                if let caption = Self.caption(for: result.match) {
                    caption
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Self.accessibilityText(for: result))
        .accessibilityIdentifier(style.testIdentifier.rawValue)
    }

    private var style: TestResultStyle { TestResultStyle(action: result.action) }

    static func accessibilityText(for result: MessageEvaluationResult) -> String {
        let title = TestResultStyle(action: result.action).title
        if let caption = result.match.caption {
            return "\(title). \(caption)"
        }
        return title
    }

    private static func caption(for match: MessageEvaluationMatch) -> Text? {
        guard let label = match.label else { return nil }
        if let value = match.value {
            return Text(label).bold() + Text(" \"\(value)\"")
        }
        return Text(label).bold()
    }
}


private struct TestResultStyle {
    let title: String
    let color: Color
    let icon: String
    let testIdentifier: TestIdentifier

    init(action: ILMessageFilterAction) {
        switch action {
        case .none, .allow:
            self.title = "testFilters_resultAllowed"~
            self.color = .green
            self.icon = "checkmark.circle.fill"
            self.testIdentifier = .testResultAllowed
        case .junk, .filter:
            self.title = "testFilters_resultJunk"~
            self.color = .red
            self.icon = "xmark.bin"
            self.testIdentifier = .testResultJunk
        case .promotion:
            self.title = "testFilters_resultPromotion"~
            self.color = .orange
            self.icon = "megaphone"
            self.testIdentifier = .testResultPromotion
        case .transaction:
            self.title = "testFilters_resultTransaction"~
            self.color = .brown
            self.icon = "arrow.left.arrow.right"
            self.testIdentifier = .testResultTransaction
        @unknown default:
            self.title = "testFilters_resultAllowed"~
            self.color = .secondary
            self.icon = "questionmark.circle"
            self.testIdentifier = .testResultAllowed
        }
    }
}


//MARK: - Preview -
#Preview("Junk") {
    FilterTesterResultRow(result: MessageEvaluationResult(action: .junk, match: .userFilter("amazon")))
        .padding()
        .adaptiveLayoutEnvironment()
}

#Preview("Allowed") {
    FilterTesterResultRow(result: MessageEvaluationResult(action: .allow, match: .noMatch))
        .padding()
        .adaptiveLayoutEnvironment()
}
