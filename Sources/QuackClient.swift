//
//  QuackClient.swift
//  Quack
//
//  Created by Christoph on 16.05.17.
//
//

import Foundation
import Alamofire
import SwiftyJSON

public enum QuackResult<T> {
    case Success(T)
    case Failure(Error)
}

public class QuackClient {
    
    let url: URL
    let manager: Alamofire.SessionManager
    
    // MARK: - Init
    
    public init(url: URL,
                timeoutInterval: TimeInterval = 5,
                serverTrustPolicies: [String: ServerTrustPolicy] = [:]) {
       self.url = url
        
        // Setup Alamofire
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = timeoutInterval
        configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        
        self.manager = Alamofire.SessionManager(configuration: configuration,
                                                serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies))
    }

    convenience public init?(urlString: String,
                             timeoutInterval: TimeInterval = 5,
                             serverTrustPolicies: [String: ServerTrustPolicy] = [:]) {
       if let url = URL(string: urlString) {
            self.init(url: url,
                      timeoutInterval: timeoutInterval,
                      serverTrustPolicies: serverTrustPolicies)
       } else {
         return nil
       }
    }
    
    // MARK: - Synchronous Response
    
    public func respond<Model: QuackModel>(method: HTTPMethod = .get,
                                           path: String,
                                           params: [String: Any] = [:],
                                           headers: [String: String] = [:],
                                           model: Model.Type) -> QuackResult<Model> {
        let result = respondWithJSON(method: method, path: path, params: params, headers: headers)
        switch result {
        case .Success(let json):
            return modelFromJSON(json: json)
        case .Failure(let error):
            return QuackResult.Failure(error)
        }
    }

    public func respondWithArray<Model: QuackModel>(method: HTTPMethod = .get,
                                                    path: String,
                                                    params: [String: Any] = [:],
                                                    headers: [String: String] = [:],
                                                    model: Model.Type) -> QuackResult<[Model]> {
        let result = respondWithJSON(method: method, path: path, params: params, headers: headers)
        switch result {
        case .Success(let json):
            return modelArrayFromJSON(json: json)
        case .Failure(let error):
            return QuackResult.Failure(error)
        }
    }
    
    private func respondWithJSON(method: HTTPMethod = .get,
                                 path: String,
                                 params: [String: Any] = [:],
                                 headers: [String: String] = [:]) -> QuackResult<JSON> {
        
        let url = self.url.appendingPathComponent(path)
        let response = Alamofire.request(url,
                                         method: method,
                                         parameters: params,
                                         headers: headers
                                         ).responseData()
        switch response.result {
        case .success(let jsonData):
            return QuackResult.Success(JSON(data: jsonData))
        case .failure(let error):
            return QuackResult.Failure(error)
        }
    }
    
    // MARK: - Asynchronous Response
    
    public func respondAsync<Model: QuackModel>(method: HTTPMethod = .get,
                                                path: String,
                                                params: [String: Any] = [:],
                                                model: Model.Type,
                                                headers: [String: String] = [:],
                                                completion: @escaping (QuackResult<Model>) -> (Void)) {
        respondWithJSONAsync(method: method, path: path, params: params, headers: headers) { result in
            switch result {
            case .Success(let json):
                completion(self.modelFromJSON(json: json))
            case .Failure(let error):
                completion(QuackResult.Failure(error))
            }
        }
    }
    
    public func respondWithArrayAsync<Model: QuackModel>(method: HTTPMethod = .get,
                                                         path: String,
                                                         params: [String: Any] = [:],
                                                         model: Model.Type,
                                                         headers: [String: String] = [:],
                                                         completion: @escaping (QuackResult<[Model]>) -> (Void)) {
        respondWithJSONAsync(method: method, path: path, params: params, headers: headers) { result in
            switch result {
            case .Success(let json):
                completion(self.modelArrayFromJSON(json: json))
            case .Failure(let error):
                completion(QuackResult.Failure(error))
            }
        }
    }
    
    private func respondWithJSONAsync(method: HTTPMethod = .get,
                                      path: String,
                                      params: [String: Any] = [:],
                                      headers: [String: String] = [:],
                                      completion: @escaping (QuackResult<JSON>) -> (Void)) {
        
        let url = self.url.appendingPathComponent(path)
        Alamofire.request(url, method: method, parameters: params, headers: headers).responseData { response in
            switch response.result {
            case .success(let jsonData):
                completion(QuackResult.Success(JSON(data: jsonData)))
            case .failure(let error):
                completion(QuackResult.Failure(error))
            }
        }
    }
    
    // MARK: - JSON - Model Handling
    
    private func modelFromJSON<Model: QuackModel>(json: JSON) -> QuackResult<Model> {
        if let model = Model(json: json) {
            return QuackResult.Success(model)
        } else {
            return QuackResult.Failure(QuackError.ModelParsingError)
        }
    }
    
    private func modelArrayFromJSON<Model: QuackModel>(json: JSON) -> QuackResult<[Model]> {
        if let jsonArray = json.array {
            var models: [Model] = []
            for jsonObject in jsonArray {
                if let model = Model(json: jsonObject) {
                    models.append(model)
                }
            }
            return QuackResult.Success(models)
        } else {
            return QuackResult.Failure(QuackError.JSONParsingError)
        }
    }

}
