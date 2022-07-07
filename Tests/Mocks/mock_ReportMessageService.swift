//
//  mock_ReportMessageService.swift
//  Tests
//
//  Created by Adi Ben-Dahan on 25/06/2022.
//

import Foundation
@testable import Simply_Filter_SMS

class mock_ReportMessageService: ReportMessageServiceProtocol {

    var reportMessageCounter = 0

    var reportMessageClosure: ((ReportMessageRequestBody) -> (Bool))?

    func reportMessage(reportMessageRequestBody: ReportMessageRequestBody) async -> Bool {
        self.reportMessageCounter += 1
        return self.reportMessageClosure?(reportMessageRequestBody) ?? false
    }

    
    func resetCounters() {
        self.reportMessageCounter = 0
    }
}
