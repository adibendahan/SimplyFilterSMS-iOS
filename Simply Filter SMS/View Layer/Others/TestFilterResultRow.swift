//
//  TestFilterResultRow.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 20/08/2026.
//

import SwiftUI
import IdentityLookup


//MARK: - View -
struct TestFilterResultRow: View {

    let result: MessageEvaluationResult

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var titleSize: CGFloat = 16

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Image(systemName: style.icon)
                .foregroundColor(style.color)
                .frame(width: iconSize, alignment: .center)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                Text(style.title)
                    .font(.system(size: titleSize, weight: .heavy))
                    .foregroundColor(style.color)

                if let caption = Self.caption(for: result.match) {
                    caption
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.leading, 8)

            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Self.accessibilityText(for: result))
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

    init(action: ILMessageFilterAction) {
        switch action {
        case .none, .allow:
            self.title = "testFilters_resultAllowed"~
            self.color = .green
            self.icon = "checkmark.circle.fill"
        case .junk, .filter:
            self.title = "testFilters_resultJunk"~
            self.color = .red
            self.icon = "xmark.bin"
        case .promotion:
            self.title = "testFilters_resultPromotion"~
            self.color = .orange
            self.icon = "megaphone"
        case .transaction:
            self.title = "testFilters_resultTransaction"~
            self.color = .brown
            self.icon = "arrow.left.arrow.right"
        @unknown default:
            self.title = "testFilters_resultAllowed"~
            self.color = .secondary
            self.icon = "questionmark.circle"
        }
    }
}


//MARK: - Preview -
#Preview("Junk") {
    TestFilterResultRow(result: MessageEvaluationResult(action: .junk, match: .userFilter("amazon")))
        .padding()
}

#Preview("Allowed") {
    TestFilterResultRow(result: MessageEvaluationResult(action: .allow, match: .noMatch))
        .padding()
}
