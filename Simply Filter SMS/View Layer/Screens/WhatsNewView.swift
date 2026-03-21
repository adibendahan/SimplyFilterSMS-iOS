//
//  WhatsNewView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 16/02/2026.
//

import SwiftUI


//MARK: - View -
struct WhatsNewView: View {

    @Environment(\.dismiss)
    var dismiss

    @ScaledMetric(relativeTo: .title2) private var entryIconSize: CGFloat = 44

    @ObservedObject var model: ViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                List {
                    ForEach(model.entries, id: \.self) { entry in
                        let row = HStack(alignment: .top, spacing: 16) {
                            Image(systemName: entry.imageName)
                                .font(.title2)
                                .foregroundColor(entry.color)
                                .frame(width: entryIconSize, height: entryIconSize)
                                .background(entry.color.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.title)
                                    .font(.body.bold())
                                    .foregroundColor(.primary)

                                if let attributed = try? AttributedString(markdown: entry.description, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                                    Text(attributed)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text(entry.description)
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .listRowSeparator(.hidden)

                        if entry.isActionable, model.onActionableEntryTapped != nil {
                            Button {
                                model.markAsSeen()
                                model.onActionableEntryTapped?(entry)
                                dismiss()
                            } label: {
                                row
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                            }
                            .accessibilityElement(children: .combine)
                            .listRowInsets(EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32))
                        } else {
                            row
                                .accessibilityElement(children: .combine)
                                .listRowInsets(EdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32))
                        }
                    }
                    .listSectionSeparator(.hidden)
                }
                .listStyle(.plain)

                Button {
                    model.markAsSeen()
                    dismiss()
                } label: {
                    Text("whatsNew_continue"~)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(FilledButton())
                .accessibilityIdentifier(TestIdentifier.callToActionButton.rawValue)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .padding(.top, 8)
            }
            .background(Color(.systemBackground))
            .navigationTitle("whatsNew_title"~)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        model.markAsSeen()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("general_close"~)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier(TestIdentifier.cancelButton.rawValue)
                }
            }
            .onDisappear {
                model.markAsSeen()
            }
        }
    }
}


//MARK: - ViewModel -
extension WhatsNewView {

    class ViewModel: BaseViewModel, ObservableObject {
        let entries: [WhatsNewEntry]
        var onActionableEntryTapped: ((WhatsNewEntry) -> Void)?

        init(appManager: AppManagerProtocol = AppManager.shared, onActionableEntryTapped: ((WhatsNewEntry) -> Void)? = nil) {
            self.entries = WhatsNewEntry.allCases.sorted { $0.order < $1.order }
            self.onActionableEntryTapped = onActionableEntryTapped
            super.init(appManager: appManager)
        }

        func markAsSeen() {
            var defaultsManager = self.appManager.defaultsManager
            guard defaultsManager.lastSeenWhatsNewVersion < currentWhatsNewVersion else { return }
            defaultsManager.lastSeenWhatsNewVersion = currentWhatsNewVersion
        }
    }
}


//MARK: - Preview -
struct WhatsNewView_Previews: PreviewProvider {
    static var previews: some View {
        WhatsNewView(model: WhatsNewView.ViewModel(appManager: AppManager.previews))
    }
}

