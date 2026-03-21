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
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme
    
    @Environment(\.dismiss)
    var dismiss
    
    @ScaledMetric(relativeTo: .title) private var logoWidth: CGFloat = 90
    @ScaledMetric(relativeTo: .body) private var socialIconSize: CGFloat = 26
    @ScaledMetric(relativeTo: .body) private var socialIconSmall: CGFloat = 22
    @ScaledMetric(relativeTo: .body) private var envelopeHeight: CGFloat = 18
    @ScaledMetric(relativeTo: .body) private var heartHeight: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var starHeight: CGFloat = 20

    @StateObject var model: ViewModel

    init(model: ViewModel) {
        _model = StateObject(wrappedValue: model)
    }

    var body: some View {
        NavigationView {
            VStack (alignment: .leading) {
                HStack(alignment: .center) {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: logoWidth, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .accessibilityHidden(true)
                    
                    ZStack(alignment: .bottomTrailing) {
                        Text("Simply Filter\nSMS")
                            .font(.largeTitle.bold())
                            .padding(.horizontal, 16)

                        Button {
                            self.model.setClipboard(content: "v\(appVersion) (\(appBuild))", displayName: "a11y_about_versionCopied"~)
                        } label: {
                            Text("v\(Text(appVersion)) (\(Text(appBuild)))")
                                .font(.caption2.italic())
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint("a11y_about_versionHint"~)
                        .padding(.top, -20)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 0)
                
                List {
                    Section {
                        if let attributed = try? AttributedString(markdown: "aboutView_aboutText"~, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
                            Text(attributed)
                                .font(.body)
                        } else {
                            Text("aboutView_aboutText"~)
                                .font(.body)
                        }

                    } header: {
                        Text("aboutView_aboutSection"~)
                    }
                    
                    Section {
                        Link(destination: .appGithubURL) {
                            HStack {
                                Image("GitHub")
                                    .resizable()
                                    .frame(width: socialIconSize, height: socialIconSize, alignment: .center)
                                    .aspectRatio(contentMode: .fit)
                                    .accessibilityLabel("GitHub")

                                VStack(alignment: .leading) {
                                    Text("aboutView_github"~)
                                        .foregroundColor(.primary)
                                        .padding(.leading, 8)
                                    
                                    Text(URL.appGithubURL.lastPathComponent)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 8)
                                        .font(.caption)
                                }
                            }
                        }

                        Button {
                            if MFMailComposeViewController.canSendMail() {
                                self.model.composeMailScreen = true
                            }
                            else {
                                self.model.setClipboard(content: kSupportEmail, displayName: "aboutView_sendMail"~)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "envelope")
                                    .resizable()
                                    .frame(width: socialIconSize, height: envelopeHeight, alignment: .center)
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading) {
                                    Text("aboutView_sendMail"~)
                                        .foregroundColor(.primary)
                                        .padding(.leading, 8)
                                    
                                    Text(kSupportEmail)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 8)
                                        .font(.caption)
                                }
                            }
                        }
                        
                        Link(destination: .appTwitterURL) {
                            HStack {
                                Image("X")
                                    .resizable()
                                    .frame(width: socialIconSize, height: socialIconSize, alignment: .center)
                                    .aspectRatio(contentMode: .fit)
                                    .accessibilityLabel("X")

                                VStack(alignment: .leading) {
                                    Text("X")
                                        .foregroundColor(.primary)
                                        .padding(.leading, 8)

                                    Text("aboutView_twitter"~)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 8)
                                        .font(.caption)
                                }
                            }
                        }
                        
                        Link(destination: .iconDesignerURL) {
                            HStack {
                                Image("Instagram")
                                    .resizable()
                                    .frame(width: socialIconSmall, height: socialIconSmall, alignment: .center)
                                    .aspectRatio(contentMode: .fit)
                                    .padding(2)
                                    .accessibilityLabel("Instagram")

                                VStack(alignment: .leading) {
                                    Text("aboutView_appIconCredit"~)
                                        .foregroundColor(.primary)
                                        .padding(.leading, 8)
                                    
                                    Text("aboutView_appIconCreditTitle"~)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 8)
                                        .font(.caption)
                                }
                            }
                        }
                        
                        Button {
                            self.model.showTipJar = true
                        } label: {
                            HStack {
                                Image(systemName: "heart.fill")
                                    .resizable()
                                    .frame(width: socialIconSmall, height: heartHeight, alignment: .center)
                                    .aspectRatio(contentMode: .fit)
                                    .padding(.horizontal, 2)
                                    .foregroundColor(.pink)

                                Text("tipJar_aboutRow"~)
                                    .foregroundColor(.primary)
                                    .padding(.leading, 8)
                            }
                        }

                        Link(destination: .appReviewURL) {
                            HStack {
                                Image(systemName: "star.fill")
                                    .resizable()
                                    .frame(width: socialIconSmall, height: starHeight, alignment: .center)
                                    .aspectRatio(contentMode: .fit)
                                    .padding(.horizontal, 2)
                                    .foregroundColor(.yellow)

                                Text("aboutView_review"~)
                                    .foregroundColor(.primary)
                                    .padding(.leading, 8)
                            }
                        }
                    } header: {
                        Text("aboutView_linksSection"~)
                    }
                }
                .listStyle(.grouped)
                .padding(.bottom, 40)

            } // VStack
            .background(Color.listBackgroundColor(for: colorScheme))
            .ignoresSafeArea(.container, edges: .bottom)
            .modifier(EmbeddedNotificationView(model: self.model.notification))
            .navigationBarTitleDisplayMode(.inline)
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
            }
            else {
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
