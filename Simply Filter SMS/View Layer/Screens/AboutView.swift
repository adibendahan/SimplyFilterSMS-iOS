//
//  AboutView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 30/12/2021.
//

import SwiftUI
import MessageUI
import UniformTypeIdentifiers


//MARK: - View -
struct AboutView: View {

    @Environment(\.dismiss)
    var dismiss

    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 22
    @ScaledMetric(relativeTo: .title) private var cardLogoSize: CGFloat = 72
    @State private var notesExpanded = false

    @StateObject var model: ViewModel

    init(model: ViewModel) {
        _model = StateObject(wrappedValue: model)
    }

    var body: some View {
        NavigationView {
            List {
                // Identity
                Section {
                    HStack(spacing: 14) {
                        Image("logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: cardLogoSize, height: cardLogoSize)
                            .clipShape(RoundedRectangle(cornerRadius: cardLogoSize * 0.225, style: .continuous))
                            .accessibilityHidden(true)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Simply Filter SMS")
                                .font(.title2.bold())
                                .foregroundColor(.primary)

                            Button {
                                model.setClipboard(content: "v\(appVersion) (\(appBuild))", displayName: "a11y_about_versionCopied"~)
                            } label: {
                                Text("v\(appVersion) (\(appBuild))")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 4)
                                    .background(.secondary.opacity(0.12))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Version \(appVersion)")
                            .accessibilityHint("a11y_about_versionHint"~)
                        }
                    }
                    .padding(.vertical, 8)
                }

                // Developer Notes (expandable)
                Section {
                    DisclosureGroup(isExpanded: $notesExpanded) {
                        Group {
                            if let attributed = try? AttributedString(markdown: "aboutView_aboutText"~, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                                Text(attributed)
                            } else {
                                Text("aboutView_aboutText"~)
                            }
                        }
                        .font(.callout)
                        .foregroundColor(.primary)
                        .padding(.bottom, 4)
                        .padding(.leading, -20)
                    } label: {
                        Label {
                            Text("aboutView_aboutSection"~)
                        } icon: {
                            Image(systemName: "quote.bubble")
                                .foregroundColor(.primary.opacity(0.4))
                        }
                    }

                    if !notesExpanded {
                        Group {
                            if let attributed = try? AttributedString(markdown: "aboutView_aboutText"~, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                                Text(attributed)
                            } else {
                                Text("aboutView_aboutText"~)
                            }
                        }
                        .font(.callout)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .padding(.bottom, -20)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                    }
                }

                // Contact
                Section("aboutView_contactSection"~) {
                    Button {
                        if MFMailComposeViewController.canSendMail() {
                            model.composeMailScreen = true
                        } else {
                            model.setClipboard(content: kSupportEmail, displayName: "aboutView_sendMail"~)
                        }
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("aboutView_sendMail"~)
                                    .foregroundColor(.primary)
                                Text(kSupportEmail)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        } icon: {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }

                // Connect
                Section("aboutView_connectSection"~) {
                    Link(destination: .appGithubURL) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("aboutView_github"~)
                                    .foregroundColor(.primary)
                                Text(URL.appGithubURL.lastPathComponent)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        } icon: {
                            Image("GitHub")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: iconSize, height: iconSize)
                        }
                    }

                    Link(destination: .appTwitterURL) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("X")
                                    .foregroundColor(.primary)
                                Text("aboutView_twitter"~)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        } icon: {
                            Image("X")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: iconSize, height: iconSize)
                        }
                    }

                    Link(destination: .iconDesignerURL) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("aboutView_appIconCredit"~)
                                    .foregroundColor(.primary)
                                Text("aboutView_appIconCreditTitle"~)
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                            }
                        } icon: {
                            Image("Instagram")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: iconSize, height: iconSize)
                        }
                    }
                }

                // Support the App
                Section("aboutView_supportSection"~) {
                    Button {
                        model.showTipJar = true
                    } label: {
                        Label {
                            Text("tipJar_aboutRow"~)
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                        }
                    }

                    Link(destination: .appReviewURL) {
                        Label {
                            Text("aboutView_review"~)
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("general_about"~)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .accessibilityLabel("general_close"~)
                    .contentShape(Rectangle())
                    .accessibilityIdentifier("AboutView.closeButton")
                }
            }
            .sheet(isPresented: $model.composeMailScreen) { } content: {
                MailView(isShowing: $model.composeMailScreen, result: $model.result)
                    .edgesIgnoringSafeArea(.bottom)
            }
            .sheet(isPresented: $model.showTipJar) {
                TipJarView(model: TipJarView.ViewModel())
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .modifier(EmbeddedNotificationView(model: model.notification))
    }
}



//MARK: - ViewModel -
extension AboutView {

    class ViewModel: BaseViewModel, ObservableObject {
        @Published var composeMailScreen: Bool = false
        @Published var showTipJar: Bool = false
        @Published var result: Result<MFMailComposeResult, Error>?
        @Published var notification: NotificationView.ViewModel

        override init(appManager: AppManagerProtocol = AppManager.shared) {
            self.notification = NotificationView.ViewModel(notification: .onClipboardSet(""))

            super.init(appManager: appManager)

            NotificationCenter.default.addObserver(forName: .onClipboardSet, object: nil, queue: .main) { not in
                guard let notficationObject = not.object as? NotificationView.Notification else { return }
                self.showNotification(notficationObject)
            }
        }

        func setClipboard(content: String, displayName: String) {
            UIPasteboard.general.setValue(content,
                        forPasteboardType: UTType.plainText.identifier)
            NotificationCenter.default.post(name: .onClipboardSet, object: NotificationView.Notification.onClipboardSet(displayName))
        }

        func showNotification(_ notification: NotificationView.Notification) {
            if !self.notification.show {
                self.notification.setNotification(notification)
                withAnimation {
                    self.notification.show = true
                }
            } else {
                withAnimation {
                    self.notification.setNotification(notification)
                }
            }
        }
    }
}

//MARK: - Preview -
struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView(model: AboutView.ViewModel(appManager: AppManager.previews))
    }
}
