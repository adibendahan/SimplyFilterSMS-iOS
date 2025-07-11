//
//  SingleButtonPage.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import SwiftUI


//MARK: - View -
struct TwoButtonPageView: View {
    
    @StateObject var model: ViewModel
    @State var coordinator: EnableExtensionView.PageCoordinator? = nil
    
    var body: some View {
        VStack (alignment: .center, spacing: 8) {
            
            ScrollView {
                Spacer()
                    .frame(height: 12, alignment: .top)
                
                Text(.init(self.model.text))
                    .font(.title2)
                    .padding(.horizontal, 16)
                
                if let image = self.model.image {
                    Spacer()
                    
                    Image(image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 45, style: .continuous))
                        .padding(.horizontal, 16)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            Button {
                withAnimation {
                    self.coordinator?.onPerform(action: model.confirmAction)
                }
            } label: {
                Text(self.model.confirmText)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(FilledButton())
            .padding(.horizontal, 16)
            .accessibilityLabel(TestIdentifier.callToActionButton.rawValue)
            
            Button {
                withAnimation {
                    self.coordinator?.onPerform(action: model.cancelAction)
                }
            } label: {
                Text(self.model.cancelText)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(OutlineButton())
            .contentShape(Rectangle())
            .padding(.horizontal, 16)
            .accessibilityLabel(TestIdentifier.cancelButton.rawValue)
            
            Spacer()
                .frame(height: 50, alignment: .bottom)
        } // VStack
        .navigationTitle(self.model.title)
    }
}


//MARK: - ViewModel -
extension TwoButtonPageView {
    
    class ViewModel: ObservableObject {
        
        @Published private(set) var title: String
        @Published private(set) var text: String
        @Published private(set) var confirmText: String
        @Published private(set) var confirmAction: EnableExtensionView.PageCoordinator.Action
        @Published private(set) var cancelText: String
        @Published private(set) var cancelAction: EnableExtensionView.PageCoordinator.Action
        @Published private(set) var image: String? = nil
        
        init(title: String,
             text: String,
             confirmText: String,
             confirmAction: EnableExtensionView.PageCoordinator.Action,
             cancelText: String,
             cancelAction: EnableExtensionView.PageCoordinator.Action,
             image: String? = nil) {
            
            self.title = title
            self.text = text
            self.confirmText = confirmText
            self.confirmAction = confirmAction
            self.cancelText = cancelText
            self.cancelAction = cancelAction
            self.image = image
        }
    }
}

extension TwoButtonPageView.ViewModel: Hashable {
    static func == (lhs: TwoButtonPageView.ViewModel, rhs: TwoButtonPageView.ViewModel) -> Bool {
        lhs.title == rhs.title
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
    }
}


//MARK: - Preview -
struct SingleButtonPage_Previews: PreviewProvider {
    static var previews: some View {
        let model = TwoButtonPageView.ViewModel(title: "enableExtension_welcome"~,
                                            text: "enableExtension_welcome_desc"~,
                                            confirmText: "enableExtension_welcome_callToAction"~,
                                            confirmAction: .nextPage,
                                            cancelText: "enableExtension_welcome_cancel"~,
                                            cancelAction: .dismiss,
                                            image: "enableExtension_screenshot4")
        
        TwoButtonPageView(model: model)
    }
}
