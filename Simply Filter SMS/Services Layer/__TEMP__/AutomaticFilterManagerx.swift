//
//  AutomaticFilterManager.swift
//  Simply Filter SMS
//
//  Created by Hod Israeli on 24/01/2022.
//

#warning("Hod - Temp implementation")
import Foundation
import NaturalLanguage

enum RequestError: Error {
    case noData
    case unknown
    case badURL
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
}

protocol URLRequestProtocol {
    var path: String { get }
    var method: HTTPMethod { get }
    var task: HTTPTask { get }
    var errorDomain: String { get }
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
        
        self.url = urlComponents?.url
    }
}

extension URL {
    static let appBaseURL = URL(string: "https://simply-filter-sms.s3.us-east-2.amazonaws.com")!
}

class URLRequestExecutor {
    func execute<T>(type: T.Type,
                    baseURL: URL,
                    request: URLRequestProtocol) async throws -> T where T: Decodable {
        
        let request = URLRequest(baseURL: baseURL, request: request)
        let (data, _) = try await URLSession.shared.data(for: request)
        
        do {
            let decodedData = try JSONDecoder().decode(T.self, from: data)
            return decodedData
        } catch {
            throw RequestError.noData
        }
    }
}

class AutomaticFiltersRequest: URLRequestProtocol {
    var path: String = "/0.0.1/AutomaticFilterList.json"
    var method: HTTPMethod = .get
    var task: HTTPTask = .requestPlain
    var errorDomain: String = "com.grizz.apps.dev.Simply-Filter-SMS.AutomaticFiltersRequest"
}

