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
    case success(T)
    case failure(Error)
}

public typealias QuackVoid = QuackResult<Void>

open class QuackClient {

    public private(set) var url: URL
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
                                           encoding: ParameterEncoding = URLEncoding.default,
                                           validStatusCodes: CountableRange<Int> = 200..<300,
                                           parser: QuackCustomModelParser? = nil,
                                           model: Model.Type) -> QuackResult<Model> {
        let result = respondWithJSON(method: method,
                                     path: path,
                                     params: params,
                                     headers: headers,
                                     encoding: encoding,
                                     validStatusCodes: validStatusCodes)
        switch result {
        case .success(let json):
            return (parser ?? self).parseModel(json: json, model: model)
        case .failure(let error):
            return QuackResult.failure(error)
        }
    }

    public func respondWithArray<Model: QuackModel>(method: HTTPMethod = .get,
                                                    path: String,
                                                    params: [String: Any] = [:],
                                                    headers: [String: String] = [:],
                                                    encoding: ParameterEncoding = URLEncoding.default,
                                                    validStatusCodes: CountableRange<Int> = 200..<300,
                                                    parser: QuackCustomArrayParser? = nil,
                                                    model: Model.Type) -> QuackResult<[Model]> {
        let result = respondWithJSON(method: method,
                                     path: path,
                                     params: params,
                                     headers: headers,
                                     encoding: encoding,
                                     validStatusCodes: validStatusCodes)
        switch result {
        case .success(let json):
            return (parser ?? self).parseArray(json: json, model: model)
        case .failure(let error):
            return QuackResult.failure(error)
        }
    }
    
    public func respondVoid(method: HTTPMethod = .get,
                            path: String,
                            params: [String: Any] = [:],
                            headers: [String: String] = [:],
                            encoding: ParameterEncoding = URLEncoding.default,
                            validStatusCodes: CountableRange<Int> = 200..<300) -> QuackVoid {
        let result = respondWithJSON(method: method,
                                     path: path,
                                     params: params,
                                     headers: headers,
                                     encoding: encoding,
                                     validStatusCodes: validStatusCodes)
        switch result {
        case .success:
            return QuackResult.success()
        case .failure(let error):
            return QuackResult.failure(error)
        }
    }
    
    // MARK: - Asynchronous Response
    
    public func respondAsync<Model: QuackModel>(method: HTTPMethod = .get,
                                                path: String,
                                                params: [String: Any] = [:],
                                                headers: [String: String] = [:],
                                                encoding: ParameterEncoding = URLEncoding.default,
                                                validStatusCodes: CountableRange<Int> = 200..<300,
                                                parser: QuackCustomModelParser? = nil,
                                                model: Model.Type,
                                                completion: @escaping (QuackResult<Model>) -> (Void)) {
        respondWithJSONAsync(method: method,
                             path: path,
                             params: params,
                             headers: headers,
                             encoding: encoding,
                             validStatusCodes: validStatusCodes) { result in
                                switch result {
                                case .success(let json):
                                    completion((parser ?? self).parseModel(json: json, model: model))
                                case .failure(let error):
                                    completion(QuackResult.failure(error))
                                }
        }
    }
    
    public func respondWithArrayAsync<Model: QuackModel>(method: HTTPMethod = .get,
                                                         path: String,
                                                         params: [String: Any] = [:],
                                                         headers: [String: String] = [:],
                                                         encoding: ParameterEncoding = URLEncoding.default,
                                                         validStatusCodes: CountableRange<Int> = 200..<300,
                                                         parser: QuackCustomArrayParser? = nil,
                                                         model: Model.Type,
                                                         completion: @escaping (QuackResult<[Model]>) -> (Void)) {
        respondWithJSONAsync(method: method,
                             path: path,
                             params: params,
                             headers: headers,
                             encoding: encoding,
                             validStatusCodes: validStatusCodes) { result in
                                switch result {
                                case .success(let json):
                                    completion((parser ?? self).parseArray(json: json, model: model))
                                case .failure(let error):
                                    completion(QuackResult.failure(error))
                                }
        }
    }
    
    public func respondVoidAsync(method: HTTPMethod = .get,
                                 path: String,
                                 params: [String: Any] = [:],
                                 headers: [String: String] = [:],
                                 encoding: ParameterEncoding = URLEncoding.default,
                                 validStatusCodes: CountableRange<Int> = 200..<300,
                                 completion: @escaping (QuackVoid) -> (Void)) {
        respondWithJSONAsync(method: method,
                             path: path,
                             params: params,
                             headers: headers,
                             encoding: encoding,
                             validStatusCodes: validStatusCodes) { result in
                                switch result {
                                case .success:
                                    completion(QuackResult.success())
                                case .failure(let error):
                                    completion(QuackResult.failure(error))
                                }
        }
    }
    
    // MARK: - Alamofire Requests
    
    private func respondWithJSON(method: HTTPMethod,
                                 path: String,
                                 params: [String: Any],
                                 headers: [String: String],
                                 encoding: ParameterEncoding,
                                 validStatusCodes: CountableRange<Int>) -> QuackResult<JSON> {
        
        let request = dataRequest(method: method,
                                  path: path,
                                  params: params, 
                                  headers: headers,
                                  encoding: encoding,
                                  validStatusCodes: validStatusCodes)
        let response = request.responseData()
        switch response.result {
        case .success(let jsonData):
            return QuackResult.success(JSON(data: jsonData))
        case .failure(let error):
            return QuackResult.failure(error)
        }
    }
    
    private func respondWithJSONAsync(method: HTTPMethod,
                                      path: String,
                                      params: [String: Any],
                                      headers: [String: String],
                                      encoding: ParameterEncoding,
                                      validStatusCodes: CountableRange<Int>,
                                      completion: @escaping (QuackResult<JSON>) -> (Void)) {
        let request = dataRequest(method: method,
                                  path: path,
                                  params: params, 
                                  headers: headers,
                                  encoding: encoding,
                                  validStatusCodes: validStatusCodes)
        request.responseData { response in
            switch response.result {
            case .success(let jsonData):
                completion(QuackResult.success(JSON(data: jsonData)))
            case .failure(let error):
                completion(QuackResult.failure(error))
            }
        }
    }
    
    private func dataRequest(method: HTTPMethod,
                             path: String,
                             params: [String: Any],
                             headers: [String: String],
                             encoding: ParameterEncoding,
                             validStatusCodes: CountableRange<Int>) -> DataRequest {
        let url = self.url.appendingPathComponent(path)
        var request = Alamofire.request(url,
                                        method: method,
                                        parameters: params,
                                        encoding: encoding,
                                        headers: headers)
        request = request.validate(statusCode: validStatusCodes)
        return request
    }
    
}

extension QuackClient: QuackCustomModelParser {
    
    public func parseModel<Model>(json: JSON, model: Model.Type) -> QuackResult<Model> where Model : QuackModel {
        if let model = Model(json: json) {
            return QuackResult.success(model)
        } else {
            return QuackResult.failure(QuackError.ModelParsingError)
        }
    }
    
}

extension QuackClient: QuackCustomArrayParser {
    
    public func parseArray<Model>(json: JSON, model: Model.Type) -> QuackResult<[Model]> where Model : QuackModel {
        if let jsonArray = json.array {
            var models: [Model] = []
            for jsonObject in jsonArray {
                if let model = Model(json: jsonObject) {
                    models.append(model)
                }
            }
            return QuackResult.success(models)
        } else {
            return QuackResult.failure(QuackError.JSONParsingError)
        }
    }
    
}
