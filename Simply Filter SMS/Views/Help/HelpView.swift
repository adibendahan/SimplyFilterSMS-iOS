//
//  HelpView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 14/01/2022.
//

import SwiftUI
import MessageUI

struct HelpView: View {
    
    @Environment(\.dismiss)
    var dismiss
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme
    
    @StateObject var model: HelpViewModel
    @State var result: Result<MFMailComposeResult, Error>? = nil
    @State var isShowingMailView = false
    @State var isShowingEnableExtensionView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack (alignment: .leading) {
                    Spacer()
                        .frame(height: 12, alignment: .top)
                    
                    Text("faq_subtitle"~)
                    
                    HStack {
                        if MFMailComposeViewController.canSendMail() {
                            Button {
                                self.isShowingMailView = true
                            } label: {
                                HStack (alignment: .center){
                                    Spacer()
                                    
                                    Image(systemName: "envelope")
                                        .resizable()
                                        .frame(width: 25, height: 20, alignment: .leading)
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.blue)
                                    
                                    Text("aboutView_sendMail"~)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                            }
                        }
                        
                        Link(destination: URL(string: "https://github.com/adibendahan/SimplyFilterSMS-iOS")!) {
                            HStack {
                                Spacer()
                                
                                Image("GitHub")
                                    .resizable()
                                    .frame(width: 26, height: 26, alignment: .center)
                                    .aspectRatio(contentMode: .fit)
                                
                                Text("aboutView_github"~)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                        }
                    }
                    
                    Spacer(minLength: 24)
                    
                    ForEach (self.model.questions) { question in
                        if question.action != .none {
                            QuestionView(
                                model: QuestionViewModel(text: question.text,
                                                         answer: question.answer,
                                                         action: question.action,
                                                         onAction: {
                                                             switch question.action {
                                                             case .activateFilters:
                                                                 isShowingEnableExtensionView = true
                                                             default:
                                                                 break
                                                             }
                                                         }))
                        }
                        else {
                            QuestionView(model: question)
                        }
                    }
                    Spacer()
                        .padding(.bottom, 50)
                } // VStack
            } // ScrollView
            .padding(.horizontal, 16)
            .background(Color.listBackgroundColor(for: colorScheme))
            .navigationTitle(self.model.title)
            .toolbar {
                ToolbarItem {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                    .contentShape(Rectangle())
                }
            }
        } // NavigationView
        .modifier(EmbeddedFooterView())
        .sheet(isPresented: $isShowingMailView) {
            MailView(isShowing: self.$isShowingMailView, result: self.$result)
                .edgesIgnoringSafeArea(.bottom)
        }
        .sheet(isPresented: $isShowingEnableExtensionView) {
            EnableExtensionView(model: EnableExtensionViewModel(showWelcome: false))
        }
    }
}

struct FrequentlyAskedView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView(model: HelpViewModel(appManager: AppManager.shared))
    }
}

