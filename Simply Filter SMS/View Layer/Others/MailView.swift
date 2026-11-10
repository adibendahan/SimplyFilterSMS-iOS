//
//  MailView.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 01/01/2022.
//

import SwiftUI
import MessageUI

struct MailView: UIViewControllerRepresentable {
    
    @Binding var isShowing: Bool
    @Binding var result: Result<MFMailComposeResult, Error>?
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(isShowing: $isShowing,
                           result: $result)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<MailView>) -> MFMailComposeViewController {
        let vc = MFMailComposeViewController()
        vc.mailComposeDelegate = context.coordinator
        vc.setToRecipients([kSupportEmail])
        return vc
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController,
                                context: UIViewControllerRepresentableContext<MailView>) {
        
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        
        @Binding var isShowing: Bool
        @Binding var result: Result<MFMailComposeResult, Error>?
        
        init(isShowing: Binding<Bool>,
             result: Binding<Result<MFMailComposeResult, Error>?>) {
            _isShowing = isShowing
            _result = result
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult,
                                   error: Error?) {
            defer {
                isShowing = false
            }
            guard error == nil else {
                Log.error("mail failed", error: error)
                self.result = .failure(error!)
                return
            }
            Log.debug("mail finished, result: \(result.logName)")
            self.result = .success(result)
        }
    }
}


private extension MFMailComposeResult {
    var logName: String {
        switch self {
        case .cancelled:
            return "cancelled"
        case .saved:
            return "saved"
        case .sent:
            return "sent"
        case .failed:
            return "failed"
        @unknown default:
            return "unknown"
        }
    }
}
