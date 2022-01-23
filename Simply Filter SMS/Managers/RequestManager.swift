//
//  RequestManager.swift
//  Simply Filter SMS
//
//  Created by Hod Israeli on 24/01/2022.
//

import Foundation

enum RequestError: Error {
    case noData
    case unknown
    case badURL
}

struct AutomaticFilterList: Codable {
    // Not sure whats the correct way to struct it here
    // Just made it work for the meantime
    let filteredLists: [String:[String]]
}

class Requester {
    func getData(completion: @escaping (Result<[AutomaticFilterList], RequestError>) -> ()) {
        guard let url = URL(string: "https://simply-filter-sms.s3.us-east-2.amazonaws.com/0.0.1/AutomaticFilterList.json") else {
            completion(.failure(.badURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error -> Void in
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString)
            }
            
            do {
                let response = try JSONDecoder().decode([AutomaticFilterList].self, from: data)
                
                if response.isEmpty {
                    completion(.failure(.noData))
                }
                else {
                    completion(.success(response))
                }
            }
            catch {
                completion(.failure(.unknown))
            }
        })
        
        task.resume()
    }
}
