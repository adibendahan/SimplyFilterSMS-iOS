//
//  ShareSheet.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 15/08/2026.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let activityViewController = UIActivityViewController(activityItems: self.items, applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { activityType, completed, _, error in
            guard let error else {
                Log.debug("share sheet closed, activity: \(activityType?.rawValue), completed: \(completed)")
                return
            }
            Log.error("share failed, activity: \(activityType?.rawValue)", error: error)
        }
        return activityViewController
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) { }
}
