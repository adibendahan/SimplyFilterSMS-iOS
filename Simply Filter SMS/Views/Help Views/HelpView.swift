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
    
    @State var result: Result<MFMailComposeResult, Error>? = nil
    @State var isShowingMailView = false
    @State var isShowingEnableExtensionView = false
    @State var questions: [Question]
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack (alignment: .bottom) {
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
                            
                            ForEach (questions) { question in
                                if question.action != .none {
                                    QuestionView(question: question) {
                                        switch question.action {
                                        case .activateFilters:
                                            isShowingEnableExtensionView = true
                                        default:
                                            break
                                        }
                                    }
                                }
                                else {
                                    QuestionView(question: question)
                                }
                            }
                            Spacer()
                                .padding(.bottom, 50)
                        } // VStack
                    } // ScrollView
                    .padding(.horizontal, 16)
                    .background(Color.listBackgroundColor(for: colorScheme))
                    .navigationTitle("filterList_menu_enableExtension"~)
                    .toolbar {
                        ToolbarItem {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 16, weight: .bold, design: .default))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    FooterView()
                } // ZStack
            } // GeometryReader
        } // NavigationView
        .sheet(isPresented: $isShowingMailView) {
            MailView(isShowing: self.$isShowingMailView, result: self.$result)
                .edgesIgnoringSafeArea(.bottom)
        }
        .sheet(isPresented: $isShowingEnableExtensionView) {
            EnableExtensionView(isFromMenu: true)
        }
    }
}

struct FrequentlyAskedView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView(questions: PersistenceController.frequentlyAskedQuestions)
    }
}

