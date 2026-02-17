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

    @ObservedObject var model: ViewModel

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("whatsNew_title"~)
                            .font(.largeTitle.bold())
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                            .padding(.bottom, 8)

                        ForEach(model.entries, id: \.self) { entry in
                            let row = HStack(alignment: .top, spacing: 16) {
                                Image(systemName: entry.imageName)
                                    .font(.title2)
                                    .foregroundColor(entry.color)
                                    .frame(width: 44, height: 44)
                                    .background(entry.color.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

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
                            .padding(.horizontal, 16)

                            if entry.isActionnable, model.onActionnableEntryTapped != nil {
                                Button {
                                    model.markAsSeen()
                                    model.onActionnableEntryTapped?(entry)
                                    dismiss()
                                } label: {
                                    row
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            } else {
                                row
                            }
                        }

                    }
                }

                Button {
                    model.markAsSeen()
                    dismiss()
                } label: {
                    Text("whatsNew_continue"~)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(FilledButton())
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .padding(.top, 8)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        model.markAsSeen()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .contentShape(Rectangle())
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
        var onActionnableEntryTapped: ((WhatsNewEntry) -> Void)?

        init(appManager: AppManagerProtocol = AppManager.shared, onActionnableEntryTapped: ((WhatsNewEntry) -> Void)? = nil) {
            self.entries = WhatsNewEntry.allCases.sorted { $0.order < $1.order }
            self.onActionnableEntryTapped = onActionnableEntryTapped
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

