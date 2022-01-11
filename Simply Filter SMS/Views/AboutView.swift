//
//  AboutView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 30/12/2021.
//

import SwiftUI
import MessageUI

struct AboutView: View {
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme
    
    @State var result: Result<MFMailComposeResult, Error>? = nil
    @State var isShowingMailView = false
    
    var body: some View {
        VStack {
            HStack(alignment: .center) {
                Image("logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 55, alignment: .center)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                VStack(alignment: .trailing) {
                    Text("Simply Filter SMS")
                        .font(.system(size: 32, weight: .bold, design: .default))
                    
                    Text("v\(Text(appVersion))")
                        .font(.footnote)
                        .italic()
                }
            }
            .padding()
            
            List {
                Section {
                    Text("aboutView_aboutText"~)
                        .font(.subheadline)
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
                            
                            Spacer()
                                .padding()
                        }
                    }
                    if MFMailComposeViewController.canSendMail() {
                        Button {
                            self.isShowingMailView = true
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
                            
                            Spacer()
                                .padding()
                        }
                    }
                } header: {
                    Text("aboutView_linksSection"~)
                } footer: {
                    Text("general_copyright"~)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .listStyle(.grouped)
        }
        .background(Color.listBackgroundColor(for: colorScheme))
        .sheet(isPresented: $isShowingMailView) {
            MailView(isShowing: self.$isShowingMailView, result: self.$result)
                .edgesIgnoringSafeArea(.bottom)
        }
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
            .previewInterfaceOrientation(.portrait)
    }
}
