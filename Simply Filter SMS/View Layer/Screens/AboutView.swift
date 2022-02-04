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
    
    @StateObject var router: AppRouter
    
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            
            List {
                Section {
                    Text("\("aboutView_aboutText"~)\(Text(.init("aboutView_appIconCredit"~)))")
                        .font(.footnote)
                } header: {
                    Text("aboutView_aboutSection"~)
                }
                
                Section {
                    Link(destination: URL(string: "https://github.com/adibendahan/SimplyFilterSMS-iOS")!) {
                        HStack {
                            Image("GitHub")
                                .resizable()
                                .frame(width: 26, height: 26, alignment: .center)
                                .aspectRatio(contentMode: .fit)
                            
                            Spacer()
                            
                            Text("aboutView_github"~)
                                .foregroundColor(.primary)
                                .padding(.leading, 8)
                            
                            Spacer()
                                .padding()
                        }
                    }
                    if MFMailComposeViewController.canSendMail() {
                        Button {
                            self.router.composeMailScreen = true
                        } label: {
                            HStack {
                                Image(systemName: "envelope")
                                    .resizable()
                                    .frame(width: 25, height: 20, alignment: .center)
                                    .aspectRatio(contentMode: .fit)
                                    .foregroundColor(.blue)
                                
                                Spacer()
                                
                                Text("aboutView_sendMail"~)
                                    .foregroundColor(.primary)
                                    .padding(.leading, 8)
                                
                                Spacer().padding()
                            }
                        }
                    }
                    Link(destination: URL(string: "https://twitter.com/a_bd")!) {
                        HStack {
                            Image("Twitter")
                                .resizable()
                                .frame(width: 26, height: 21, alignment: .center)
                                .aspectRatio(contentMode: .fit)
                            
                            Spacer()
                            
                            Text("aboutView_twitter"~)
                                .foregroundColor(.primary)
                                .padding(.leading, 8)
                            
                            
                            Spacer()
                                .padding()
                        }
                    }
                } header: {
                    Text("aboutView_linksSection"~)
                }
            }
            .listStyle(.insetGrouped)
            .padding(.bottom, 40)
        } // VStack
        .background(Color.listBackgroundColor(for: colorScheme))
        .modifier(EmbeddedFooterView())
        .modifier(EmbeddedCloseButton(onTap: { dismiss() }))
    }
}


//MARK: - Preview -
struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView(router: AppRouter(appManager: AppManager.previews()))
    }
}
