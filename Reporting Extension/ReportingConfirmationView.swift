//
//  ReportingConfirmationView.swift
//  Reporting Extension
//

import SwiftUI

struct ReportingConfirmationView: View {
    @ObservedObject var model: ViewModel

    private let reportTypes: [ReportType] = [.junk, .junkAndBlockSender, .notJunk]

    var body: some View {
        List(reportTypes, id: \.id) { reportType in
            Button {
                model.selectedReportType = reportType
            } label: {
                HStack {
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
        .listStyle(.insetGrouped)
    }
}

extension ReportingConfirmationView {
    class ViewModel: ObservableObject {
        @Published var selectedReportType: ReportType?
    }
}
