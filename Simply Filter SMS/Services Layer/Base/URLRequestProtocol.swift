//
//  URLRequestProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 13/02/2022.
//

import Foundation

protocol URLRequestProtocol {
    var url: URL { get }
    var method: HTTPMethod { get }
    var task: HTTPTask { get }
    var headers: [String: String] { get }
    var errorDomain: String { get }
}

extension URLRequestProtocol {
    var headers: [String: String] {
        return [:]
    }
}

extension Dictionary where Key == String, Value == String {
    static func ifNoneMatch(_ etag: String?) -> [String: String] {
        guard let etag = etag else { return [:] }
        return ["If-None-Match": etag]
    }
}

extension URLRequest {
    init(request: URLRequestProtocol) {
        var urlComponents = URLComponents(url: request.url, resolvingAgainstBaseURL: false)
        guard let componentsURL = urlComponents?.url else { fatalError("no url") }
        
        self.init(url: componentsURL)
        
        self.httpMethod = request.method.rawValue

        for (field, value) in request.headers {
            self.setValue(value, forHTTPHeaderField: field)
        }
        
        switch request.task {
        case .requestPlain:
            return
            
        case .requestParameters(let bodyParameters, let urlParameters):
            if let bodyParams = bodyParameters {
                self.addValue("application/json", forHTTPHeaderField: "Content-Type")
                self.httpBody = try? JSONSerialization.data(withJSONObject: bodyParams)
            }
            if let urlParams = urlParameters {
                urlComponents?.queryItems = []
                for urlParam in urlParams {
                    urlComponents?.queryItems?.append(URLQueryItem(name: urlParam.key, value: urlParam.value))
                }
            }
        }

        self.url = urlComponents?.url
    }
}

typealias URLParameters = [String: String]
typealias BodyParameters = [String: Any]

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

enum HTTPTask {
    case requestPlain
    case requestParameters(bodyParameters: BodyParameters?, urlParameters: URLParameters?)
    
    var isPlain: Bool {
        switch self {
        case .requestPlain:
            return true
        case .requestParameters(_,_):
            return false
        }
    }
}

enum RequestError: Error {
    case noData
    case badStatus(Int)
    case unknown
}
