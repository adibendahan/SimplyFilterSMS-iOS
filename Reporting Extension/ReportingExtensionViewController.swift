//
//  ReportingExtensionViewController.swift
//  Reporting Extension
//

import UIKit
import SwiftUI
import IdentityLookupUI
import Combine

class ReportingExtensionViewController: ILClassificationUIExtensionViewController {

    private let confirmationViewModel = ReportingConfirmationView.ViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var pendingSender: String = ""
    private var pendingBodies: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        let hostingController = UIHostingController(rootView: ReportingConfirmationView(model: confirmationViewModel))
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)

        confirmationViewModel.$selectedReportType
            .map { $0 != nil }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isReady in
                self?.extensionContext.isReadyForClassificationResponse = isReady
            }
            .store(in: &cancellables)
    }

    override func prepare(for classificationRequest: ILClassificationRequest) {
        if let messageRequest = classificationRequest as? ILMessageClassificationRequest,
           let first = messageRequest.messageCommunications.first {
            pendingSender = first.sender ?? ""
            pendingBodies = messageRequest.messageCommunications.compactMap { $0.messageBody }.filter { !$0.isEmpty }
            confirmationViewModel.sender = pendingSender
            confirmationViewModel.bodies = pendingBodies
        }
    }

    override func classificationResponse(for request: ILClassificationRequest) -> ILClassificationResponse {
        guard let reportType = confirmationViewModel.selectedReportType else {
            return ILClassificationResponse(action: .none)
        }

        let action: ILClassificationAction
        switch reportType {
        case .junk:
            action = .reportJunk
        case .notJunk:
            action = .reportNotJunk
        case .junkAndBlockSender:
            action = .reportJunkAndBlockSender
        }

        let response = ILClassificationResponse(action: action)
        response.userInfo = [
            "sender": pendingSender,
            "bodies": pendingBodies,
            "type": reportType.type
        ]
        return response
    }
}
