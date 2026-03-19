//
//  ReportingConfirmationView.swift
//  Reporting Extension
//

import SwiftUI

struct ReportingConfirmationView: View {
    @ObservedObject var model: ViewModel

    private let reportTypes: [ReportType] = [.junk, .junkAndBlockSender, .notJunk]

    var body: some View {
        ZStack(alignment: .bottom) {
        List {
            Section {
                VStack(alignment: .leading, spacing: 0) {
                    if !model.sender.isEmpty {
                        Label(model.sender, systemImage: "person.fill")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                            .padding(.bottom, model.bodies.isEmpty ? 0 : 10)
                    }
                    ForEach(Array(model.bodies.enumerated()), id: \.offset) { index, body in
                        if !model.sender.isEmpty || index > 0 {
                            Divider()
                                .padding(.bottom, 10)
                        }
                        Text(model.bodies.count > 1 ? String(format: "reportingExtension_messageIndex"~, index + 1) : "reportingExtension_message"~)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 2)
                        Text(body)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .lineLimit(4)
                            .padding(.bottom, index < model.bodies.count - 1 ? 10 : 0)
                    }
                }
                .padding(.vertical, 4)
            } header: {
                Text(String.localizedStringWithFormat("reportingExtension_selectedMessage"~, model.bodies.count))
                    .font(.headline)
                    .foregroundColor(.primary)
                    .textCase(nil)
                    .padding(.bottom, 4)
            }

            Section {
                ForEach(reportTypes, id: \.id) { reportType in
                    Button {
                        model.selectedReportType = reportType
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: reportType.icon)
                                .foregroundColor(reportType.color)
                                .frame(width: 24)
                            Text(reportType.name)
                                .foregroundColor(.primary)
                            Spacer()
                            if model.selectedReportType == reportType {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                                    .font(.body.weight(.semibold))
                            }
                        }
                        .contentShape(Rectangle())
                    }
                }
            } header: {
                Text(String.localizedStringWithFormat("reportingExtension_classify"~, model.bodies.count))
                    .font(.headline)
                    .foregroundColor(.primary)
                    .textCase(nil)
                    .padding(.bottom, 4)
            } footer: {
                Text("reportingExtension_footer"~)
                    .multilineTextAlignment(.center)
            }
        }
        .listStyle(.insetGrouped)
        FooterView()
            .ignoresSafeArea(.keyboard, edges: .all)
        }
    }
}

extension ReportingConfirmationView {
    class ViewModel: ObservableObject {
        @Published var selectedReportType: ReportType?
        @Published var sender: String = ""
        @Published var bodies: [String] = []
    }
}
