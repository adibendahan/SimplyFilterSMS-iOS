//
//  AutomaticFilterManager.swift
//  Simply Filter SMS
//
//  Created by Hod Israeli on 24/01/2022.
//

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

enum Task {
    case requestPlain
    case requestParameters(bodyParameters: BodyParameters?, urlParameters: URLParameters?)
}

protocol URLRequestProtocol {
    var path: String { get }
    var method: HTTPMethod { get }
    var task: Task { get }
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


protocol AutomaticFilterManagerProtocol {
    var availableRules: [RuleType] { get }
    
    func automaticRuleState(for rule: RuleType) -> Bool
    func setAutomaticRuleState(for rule: RuleType, value: Bool)
    
    func fetchAutomaticFilterList(completion: @escaping (AutomaticFilterList?) -> ())
    func forceUpdateAutomaticFilters(completion: (()->())?)
}

class URLRequestExecutor {
    func execute<T>(type: T.Type,
                    baseURL: URL,
                    request: URLRequestProtocol,
                    completion: @escaping (Result<T, RequestError>) -> ()) where T: Decodable {
        
        let request = URLRequest(baseURL: baseURL, request: request)
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
            
            do {
                let response = try JSONDecoder().decode(T.self, from: data)
                completion(.success(response))
            }
            catch {
                completion(.failure(.unknown))
            }
        })
        
        task.resume()
    }
}

class AutomaticFiltersRequest: URLRequestProtocol {
    var path: String = "/0.0.1/AutomaticFilterList.json"
    var method: HTTPMethod = .get
    var task: Task = .requestPlain
    var errorDomain: String = "com.grizz.apps.dev.Simply-Filter-SMS.AutomaticFiltersRequest"
}

class AutomaticFilterManager: AutomaticFilterManagerProtocol {
    
    private let urlRequestExecutor = URLRequestExecutor()
    private let persistanceManager: PersistanceManagerProtocol
    
    init(persistanceManager: PersistanceManagerProtocol = AppManager.shared.persistanceManager) {
        self.persistanceManager = persistanceManager
        
        persistanceManager.initAutomaticFiltering()
        self.fetchFiltersIfNeeded()
    }
    
    func fetchAutomaticFilterList(completion: @escaping (AutomaticFilterList?) -> ()) {
        
        self.urlRequestExecutor.execute(type: AutomaticFilterList.self,
                                        baseURL: .appBaseURL,
                                        request: AutomaticFiltersRequest()) { result in
            
            switch result {
            case .success(let filterList):
                completion(filterList)
            case .failure(let error):
                print("ERROR: \(error)")
                completion(nil)
            }
        }
    }
    
    func forceUpdateAutomaticFilters(completion: (()->())?) {
        self.fetchAutomaticFilterList { [weak self] automaticFilterList in
            guard let automaticFilterList = automaticFilterList else { return }
            
            self?.updateCacheIfNeeded(newFilterList: automaticFilterList, force: true)
            completion?()
        }
    }
    
    var availableRules: [RuleType] {
        return RuleType.allCases
    }
    
    func automaticRuleState(for rule: RuleType) -> Bool {
        return self.persistanceManager.automaticRuleState(for: rule)
    }
    
    func setAutomaticRuleState(for rule: RuleType, value: Bool) {
        self.persistanceManager.setAutomaticRuleState(for: rule, value: value)
    }
    
    private func updateCacheIfNeeded(newFilterList: AutomaticFilterList, force: Bool = false) {
        guard force || self.persistanceManager.isCacheStale(comparedTo: newFilterList) else { return }
        self.persistanceManager.cacheAutomaticFilterList(newFilterList)
    }
    
    private var shouldFetchFilters: Bool {
        var shouldFetchFilters = true
        
        if let cacheAge = self.persistanceManager.automaticFiltersCacheAge,
           cacheAge.daysBetween(date: Date()) < 3 {
            
            shouldFetchFilters = false
        }
        
        return shouldFetchFilters
    }
    
    private func fetchFiltersIfNeeded() {
        guard self.shouldFetchFilters else { return }
        
        self.fetchAutomaticFilterList { [weak self] automaticFilterList in
            guard let automaticFilterList = automaticFilterList else { return }
            
            self?.updateCacheIfNeeded(newFilterList: automaticFilterList)
        }
    }
}
