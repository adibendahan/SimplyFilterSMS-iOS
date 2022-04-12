//
//  AboutView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 30/12/2021.
//

import SwiftUI
import MessageUI


//MARK: - View -
struct AboutView: View {
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme
    
    @Environment(\.dismiss)
    var dismiss
    
    @ObservedObject var model: ViewModel
    
    var body: some View {
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
            .padding(.top, 46)
            
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

                            Text("aboutView_github"~)
                                .foregroundColor(.primary)
                                .padding(.leading, 8)

                        }
                    }
                    if MFMailComposeViewController.canSendMail() {
                        Button {
                            self.model.composeMailScreen = true
                        } label: {
                            HStack {
                                Image(systemName: "envelope")
                                    .resizable()
                                    .frame(width: 26, height: 18, alignment: .center)
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.secondary)

                                Text("aboutView_sendMail"~)
                                    .foregroundColor(.primary)
                                    .padding(.leading, 8)
                            }
                        }
                    }
                    Link(destination: .appTwitterURL) {
                        HStack {
                            Image("Twitter")
                                .resizable()
                                .frame(width: 26, height: 21, alignment: .center)
                                .aspectRatio(contentMode: .fit)

                            Text("aboutView_twitter"~)
                                .foregroundColor(.primary)
                                .padding(.leading, 8)
                        }
                    }
                    Link(destination: .iconDesignerURL) {
                        HStack {
                            Image("Instagram")
                                .resizable()
                                .frame(width: 22, height: 22, alignment: .center)
                                .aspectRatio(contentMode: .fit)
                                .padding(2)

                            Text(.init("aboutView_appIconCredit"~))
                                .foregroundColor(.primary)
                                .padding(.leading, 8)
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
        .modifier(EmbeddedCloseButton(onTap: { dismiss() }))
        .sheet(isPresented: $model.composeMailScreen) { } content: {
            MailView(isShowing: $model.composeMailScreen, result: $model.result)
                            .edgesIgnoringSafeArea(.bottom)
        }
    }
}


//MARK: - ViewModel -
extension AboutView {
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published var composeMailScreen: Bool = false
        @Published var result: Result<MFMailComposeResult, Error>?
    }
}

//MARK: - Preview -
struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView(model: AboutView.ViewModel(appManager: AppManager.previews))
    }
}
