//
//  URLRequestProtocol.swift
//  Simply Filter SMS
//
//  Created by Adi Ben-Dahan on 13/02/2022.
//

import Foundation

protocol URLRequestProtocol {
    var path: String { get }
    var method: HTTPMethod { get }
    var task: HTTPTask { get }
    var errorDomain: String { get }
    var auth: Bool { get }
}

extension URLRequest {
    init(baseURL: URL?, request: URLRequestProtocol) {
        guard let url = baseURL?.appendingPathComponent(request.path) else { fatalError("no url")}
        var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
        guard let componentsURL = urlComponents?.url else { fatalError("no url") }
        
        self.init(url: componentsURL)
        
        self.httpMethod = request.method.rawValue
        
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
        
        if request.auth,
           let apiKey = Bundle.main.infoDictionary?["API_KEY"] as? String {
            self.addValue(apiKey, forHTTPHeaderField: "x-api-key")
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
    case unknown
}
