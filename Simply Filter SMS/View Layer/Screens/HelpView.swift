//
//  HelpView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 14/01/2022.
//

import SwiftUI
import MessageUI


//MARK: - View -
struct HelpView: View {
    
    @Environment(\.dismiss)
    var dismiss
    
    @Environment(\.colorScheme)
    var colorScheme: ColorScheme
    
    @ScaledMetric(relativeTo: .body) private var envelopeWidth: CGFloat = 25
    @ScaledMetric(relativeTo: .body) private var envelopeHeight: CGFloat = 20
    @ScaledMetric(relativeTo: .body) private var githubIconSize: CGFloat = 26

    @ObservedObject var model: ViewModel
    
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
                                self.model.composeMailScreen = true
                            } label: {
                                HStack (alignment: .center){
                                    Spacer()
                                    
                                    Image(systemName: "envelope")
                                        .resizable()
                                        .frame(width: envelopeWidth, height: envelopeHeight, alignment: .leading)
                                        .aspectRatio(contentMode: .fit)
                                        .foregroundColor(.blue)
                                    
                                    Text("aboutView_sendMail"~)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                }
                            }
                        }
                        
                        Link(destination: .appGithubURL) {
                            HStack {
                                Spacer()
                                
                                Image("GitHub")
                                    .resizable()
                                    .frame(width: githubIconSize, height: githubIconSize, alignment: .center)
                                    .aspectRatio(contentMode: .fit)
                                    .accessibilityLabel("GitHub")
                                
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
                                model: QuestionView.ViewModel(text: question.text,
                                                              answer: question.answer,
                                                              action: question.action,
                                                              onAction: {
                                                                  switch question.action {
                                                                  case .activateFilters:
                                                                      self.model.onRequestScreen?(.enableExtension)
                                                                      dismiss()
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
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                    }
                    .accessibilityLabel("general_close"~)
                    .contentShape(Rectangle())
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .modifier(EmbeddedFooterView(onTap: {
            self.model.onRequestScreen?(.about)
            dismiss()
        }))
        .sheet(item: $model.sheetScreen) { } content: { sheetScreen in
            sheetScreen.build()
        }
        .sheet(isPresented: $model.composeMailScreen) { } content: {
            MailView(isShowing: $model.composeMailScreen, result: $model.result)
                            .edgesIgnoringSafeArea(.bottom)
        }
    }
}


//MARK: - ViewModel -
extension HelpView {
    
    class ViewModel: BaseViewModel, ObservableObject {
        @Published private(set) var questions: [QuestionView.ViewModel]
        @Published private(set) var title: String
        @Published var sheetScreen: Screen? = nil
        @Published var composeMailScreen: Bool = false
        @Published var result: Result<MFMailComposeResult, Error>?
        var onRequestScreen: ((Screen) -> Void)?

        init(appManager: AppManagerProtocol = AppManager.shared,
             onRequestScreen: ((Screen) -> Void)? = nil) {
            self.title = "filterList_menu_enableExtension"~
            self.questions = appManager.getFrequentlyAskedQuestions()
            self.onRequestScreen = onRequestScreen

            super.init(appManager: appManager)
        }
    }
}


//MARK: - Preview -
struct FrequentlyAskedView_Previews: PreviewProvider {
    static var previews: some View {
        HelpView(model: HelpView.ViewModel(appManager: AppManager.previews))
    }
}

