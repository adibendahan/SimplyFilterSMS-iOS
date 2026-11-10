//
//  Log.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 10/11/2026.
//

import Foundation
import OSLog

enum Log {

    
    //MARK: - Public API -
    static func debug(_ message: @autoclosure () -> Message,
                      file: String = #fileID,
                      function: String = #function,
                      line: Int = #line) {

        let text = self.text(message().text, file: file, function: function, line: line)
        self.logger.debug("\(text, privacy: .public)")
    }

    static func error(_ message: @autoclosure () -> Message,
                      error: Error? = nil,
                      file: String = #fileID,
                      function: String = #function,
                      line: Int = #line) {

        let text = self.text(message().persistedText, error: error, file: file, function: function, line: line)
        self.logger.error("\(text, privacy: .public)")
    }

    static func fault(_ message: @autoclosure () -> Message,
                      error: Error? = nil,
                      file: String = #fileID,
                      function: String = #function,
                      line: Int = #line) {

        let text = self.text(message().persistedText, error: error, file: file, function: function, line: line)
        self.logger.fault("\(text, privacy: .public)")
    }


    //MARK: - Message -
    struct Message: ExpressibleByStringInterpolation {
        let text: String
        let redactedText: String

        var persistedText: String {
            #if DEBUG
            return self.text
            #else
            return self.redactedText
            #endif
        }

        init(stringLiteral value: String) {
            self.text = value
            self.redactedText = value
        }

        init(stringInterpolation: Interpolation) {
            self.text = stringInterpolation.text
            self.redactedText = stringInterpolation.redactedText
        }

        struct Interpolation: StringInterpolationProtocol {
            var text = ""
            var redactedText = ""

            init(literalCapacity: Int, interpolationCount: Int) {
                self.text.reserveCapacity(literalCapacity)
                self.redactedText.reserveCapacity(literalCapacity)
            }

            mutating func appendLiteral(_ literal: String) {
                self.text += literal
                self.redactedText += literal
            }

            mutating func appendInterpolation(_ value: String?) {
                self.appendValue(value)
            }

            mutating func appendInterpolation<T: BinaryInteger>(_ value: T?) {
                self.appendValue(value.map({ "\($0)" }))
            }

            mutating func appendInterpolation(_ value: Bool?) {
                self.appendValue(value.map({ "\($0)" }))
            }

            mutating func appendInterpolation(_ value: Double?) {
                self.appendValue(value.map(Log.roundedText))
            }

            mutating func appendInterpolation(_ value: Date?) {
                self.appendValue(value.map(Log.dateText))
            }

            mutating func appendInterpolation(duration value: TimeInterval?) {
                self.appendValue(value.map(Log.durationText))
            }

            mutating func appendInterpolation(_ value: URL?) {
                self.appendValue(value?.absoluteString)
            }

            mutating func appendInterpolation(_ value: UUID?) {
                self.appendValue(value?.uuidString)
            }

            mutating func appendInterpolation<T: CaseIterable>(_ value: T?) {
                self.appendValue(value.map({ String(describing: $0) }))
            }

            mutating func appendInterpolation(_ values: [String]) {
                self.appendList(values)
            }

            mutating func appendInterpolation<T: CaseIterable>(_ values: [T]) {
                self.appendList(values.map({ String(describing: $0) }))
            }

            mutating func appendInterpolation(_ values: Set<String>) {
                self.appendList(values.sorted())
            }

            mutating func appendInterpolation<T: CaseIterable>(_ values: Set<T>) {
                self.appendList(values.map({ String(describing: $0) }).sorted())
            }

            mutating func appendInterpolation(matched: Bool) {
                self.appendLiteral(matched ? "match" : "no match")
            }

            mutating func appendInterpolation(private value: String?) {
                guard let value else {
                    self.appendLiteral("nil")
                    return
                }
                self.text += Log.quoted(value)
                self.redactedText += "<private>"
            }

            private mutating func appendList(_ values: [String]) {
                self.appendValue("[\(values.joined(separator: ", "))]")
            }

            private mutating func appendValue(_ value: String?) {
                guard let value else {
                    self.appendLiteral("nil")
                    return
                }
                let quotedValue = Log.quoted(value)
                self.text += quotedValue
                self.redactedText += quotedValue
            }
        }
    }


    //MARK: - Private -
    private static let logger = Logger(subsystem: "com.grizz.apps.dev.Simply-Filter-SMS",
                                       category: ProcessInfo.processInfo.processName)

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        return formatter
    }()

    private static let durationFormatter: DateComponentsFormatter = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        let formatter = DateComponentsFormatter()
        formatter.calendar = calendar
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter
    }()

    private static func durationText(_ duration: TimeInterval) -> String {
        return self.durationFormatter.string(from: duration) ?? "\(duration)"
    }

    private static func dateText(_ date: Date) -> String {
        return self.dateFormatter.string(from: date)
    }

    private static func roundedText(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        return "\(rounded)"
    }

    private static func quoted(_ value: String) -> String {
        let escapedValue = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\n", with: "\\n")
        return "'\(escapedValue)'"
    }

    private static func text(_ message: String,
                             error: Error? = nil,
                             file: String,
                             function: String,
                             line: Int) -> String {

        let fileName = file.split(separator: "/").last.map(String.init) ?? file
        let typeName = fileName.replacingOccurrences(of: ".swift", with: "")
        let methodName = function.split(separator: "(").first.map(String.init) ?? function
        let text = "[\(typeName).\(methodName):\(line)] \(message)"

        guard let error else { return text }

        let nsError = error as NSError
        let domain = self.quoted(nsError.domain)
        let code = self.quoted("\(nsError.code)")
        let description = self.quoted(nsError.localizedDescription)
        let userInfo = self.quoted("\(nsError.userInfo)")
        return "\(text), error domain: \(domain), code: \(code), description: \(description), userInfo: \(userInfo)"
    }
}
