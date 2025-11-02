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
    
    @ObservedObject var model: ViewModel
    
    var body: some View {
        NavigationView {
            VStack (alignment: .leading) {
                HStack(alignment: .center) {
                    Image("logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 90, alignment: .center)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    
                    ZStack(alignment: .bottomTrailing) {
                        Text("Simply Filter\nSMS")
                            .font(.largeTitle.bold())
                            .padding(.horizontal, 16)
                        
                        Text("v\(Text(appVersion)) (\(Text(appBuild)))")
                            .font(.caption2.italic())
                            .padding(.top, -20)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 0)
                
                List {
                    Section {
                        Text("aboutView_aboutText"~)
                            .font(.body)
                    } header: {
                        Text("aboutView_aboutSection"~)
                    }
                    
                    Section {
                        Link(destination: .appGithubURL) {
                            HStack {
                                Image("GitHub")
                                    .resizable()
                                    .frame(width: 26, height: 26, alignment: .center)
                                    .aspectRatio(contentMode: .fit)

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
                                    .frame(width: 26, height: 18, alignment: .center)
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
                                Image("Twitter")
                                    .resizable()
                                    .frame(width: 26, height: 21, alignment: .center)
                                    .aspectRatio(contentMode: .fit)

                                VStack(alignment: .leading) {
                                    Text("Twitter")
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
                                    .frame(width: 22, height: 22, alignment: .center)
                                    .aspectRatio(contentMode: .fit)
                                    .padding(2)

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
                        
                        Link(destination: .appReviewURL) {
                            HStack {
                                Image(systemName: "suit.heart.fill")
                                    .resizable()
                                    .frame(width: 22, height: 20, alignment: .center)
                                    .aspectRatio(contentMode: .fit)
                                    .padding(.horizontal, 2)
                                    .foregroundColor(.red)
                                
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
                    .contentShape(Rectangle())
                    .accessibilityIdentifier("AboutView.closeButton")
                }
            }
            .sheet(isPresented: $model.composeMailScreen) { } content: {
                MailView(isShowing: $model.composeMailScreen, result: $model.result)
                                .edgesIgnoringSafeArea(.bottom)
            }
        }
        .ignoresSafeArea(.container, edges: .bottom)
    }
}


//MARK: - ViewModel -
extension AboutView {
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published var composeMailScreen: Bool = false
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
            
            if let timeout = notification.timeout {
                DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
                    withAnimation {
                        self.notification.show = false
                    }
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
