//
//  CustomPlaceholderView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 02/01/2025.
//
import SwiftUI


struct CustomPlaceholderView: View {

    var body: some View {
        var symbol: String {
            let languageCode = Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en"
            switch languageCode {
                case "he": return "sidebar.right"
                default: return "sidebar.left"
            }
        }
        
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "square.text.square")
                .font(.system(size: 60))
                .foregroundColor(.primary)
            
            Text("placeholder_choose_title"~)
                .font(.title2)
                .foregroundColor(.primary)
            
            VStack (spacing: 5) {
                Text("placeholder_choose_detail"~)
                    .font(.body)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack {
                    Text("placeholder_choose_sub_detail1"~)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                    
                    Image(systemName: symbol)
                        .font(.body)
                        .foregroundColor(.accentColor)
                    
                    Text("placeholder_choose_sub_detail2"~)
                        .font(.body)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }

            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}



//MARK: - Preview -
struct CustomPlaceholderView_Previews: PreviewProvider {
    static var previews: some View {
        CustomPlaceholderView()
    }
}
