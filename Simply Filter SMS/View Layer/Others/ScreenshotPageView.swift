//
//  ScreenshotPageView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 23/01/2022.
//

import SwiftUI


//MARK: - View -
struct ScreenshotPageView: View {
    
    @StateObject var model: Model
    @State var coordinator: EnableExtensionView.PageCoordinator? = nil
    
    var body: some View {
        VStack {
            ScrollView {
                VStack (alignment: .leading, spacing: 8) {
                    Spacer()
                    
                    Text(self.model.text)
                        .font(.title2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Spacer()
                    
                    Image(self.model.image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 45, style: .continuous))
                    
                    Spacer(minLength: 50)
                }
            }
            .padding(.horizontal, 16)
            
            Spacer(minLength: 20)
            
            Button {
                self.coordinator?.onPerform(action: model.confirmAction)
            } label: {
                Text(self.model.confirmText)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(FilledButton())
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
            
            Spacer()
                .frame(height: 50, alignment: .bottom)
        }
        .navigationTitle(self.model.title)
    }
}


//MARK: - Model -
extension ScreenshotPageView {
    
    class Model: ObservableObject {
        
        private var id = UUID()
        @Published var title: String
        @Published var text: String
        @Published var image: String
        @Published var confirmText: String
        @Published var confirmAction: EnableExtensionView.PageCoordinator.Action
        
        init(title: String,
             text: String,
             image: String,
             confirmText: String,
             confirmAction: EnableExtensionView.PageCoordinator.Action) {
            
            self.title = title
            self.text = text
            self.image = image
            self.confirmText = confirmText
            self.confirmAction = confirmAction
        }
    }
}

extension ScreenshotPageView.Model: Hashable {
    static func == (lhs: ScreenshotPageView.Model, rhs: ScreenshotPageView.Model) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}


//MARK: - Preview -
struct ScreenshotPageView_Previews: PreviewProvider {
    static var previews: some View {
        let model = ScreenshotPageView.Model(title: "enableExtension_step2"~,
                                             text: "enableExtension_step2_desc"~,
                                             image: "enableExtension_screenshot2",
                                             confirmText: "enableExtension_next"~,
                                             confirmAction: .nextPage)
        ScreenshotPageView(model: model)
    }
}
