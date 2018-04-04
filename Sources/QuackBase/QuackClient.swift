//
//  QuackClient.swift
//  Quack
//
//  Created by Christoph on 16.05.17.
//
//

import Foundation
import SwiftyJSON
import Dispatch


extension Quack {
    
    open class ClientBase {
        
        public private(set) var url: URL
        public private(set) var timeoutInterval: TimeInterval
        
        // MARK: - Init
        
        public init(url: URL, timeoutInterval: TimeInterval = 5) {
            self.url = url
            self.timeoutInterval = timeoutInterval
        }
        
        convenience public init?(urlString: String, timeoutInterval: TimeInterval = 5) {
            if let url = URL(string: urlString) {
                self.init(url: url, timeoutInterval: timeoutInterval)
            } else {
                return nil
            }
        }
        
        // MARK: - Methods overridden by subclasses
        
        open func _respondWithJSON(method: Quack.HTTP.Method,
                                   path: String,
                                   body: [String: Any],
                                   headers: [String: String],
                                   validStatusCodes: CountableRange<Int>,
                                   requestModification: ((Quack.Request) -> (Quack.Request))?) -> Quack.Result<JSON> {
            fatalError("this method must be implemented in subclass")
        }
        
        open func _respondWithJSONAsync(method: Quack.HTTP.Method,
                                        path: String,
                                        body: [String: Any],
                                        headers: [String: String],
                                        validStatusCodes: CountableRange<Int>,
                                        requestModification: ((Quack.Request) -> (Quack.Request))?,
                                        completion: @escaping (Quack.Result<JSON>) -> (Swift.Void)) {
            fatalError("this method must be implemented in subclass")
        }
        
    }
    
}

// MARK: - Synchronous Response

public extension Quack.ClientBase {
    
    public func respond<Model: Quack.Model>(method: Quack.HTTP.Method = .get,
                                            path: String,
                                            body: [String: Any] = [:],
                                            headers: [String: String] = [:],
                                            validStatusCodes: CountableRange<Int> = 200..<300,
                                            parser: Quack.CustomModelParser? = nil,
                                            model: Model.Type,
                                            requestModification: ((Quack.Request) -> (Quack.Request))? = nil) -> Quack.Result<Model> {
        let result = _respondWithJSON(method: method,
                                      path: path,
                                      body: body,
                                      headers: headers,
                                      validStatusCodes: validStatusCodes,
                                      requestModification: requestModification)
        switch result {
        case .success(let json):
            return (parser ?? self).parseModel(json: json, model: model)
        case .failure(let error):
            return Quack.Result.failure(error)
        }
    }

    public func respondWithArray<Model: Quack.Model>(method: Quack.HTTP.Method = .get,
                                                     path: String,
                                                     body: [String: Any] = [:],
                                                     headers: [String: String] = [:],
                                                     validStatusCodes: CountableRange<Int> = 200..<300,
                                                     parser: Quack.CustomArrayParser? = nil,
                                                     model: Model.Type,
                                                     requestModification: ((Quack.Request) -> (Quack.Request))? = nil) -> Quack.Result<[Model]> {
        let result = _respondWithJSON(method: method,
                                      path: path,
                                      body: body,
                                      headers: headers,
                                      validStatusCodes: validStatusCodes,
                                      requestModification: requestModification)
        switch result {
        case .success(let json):
            return (parser ?? self).parseArray(json: json, model: model)
        case .failure(let error):
            return Quack.Result.failure(error)
        }
    }

    public func respondVoid(method: Quack.HTTP.Method = .get,
                            path: String,
                            body: [String: Any] = [:],
                            headers: [String: String] = [:],
                            validStatusCodes: CountableRange<Int> = 200..<300,
                            requestModification: ((Quack.Request) -> (Quack.Request))? = nil) -> Quack.Void {
        let result = _respondWithJSON(method: method,
                                      path: path,
                                      body: body,
                                      headers: headers,
                                      validStatusCodes: validStatusCodes,
                                      requestModification: requestModification)
        switch result {
        case .success:
            return Quack.Result.success(())
        case .failure(let error):
            return Quack.Result.failure(error)
        }
    }
    
}

// MARK: - Asynchronous Response

public extension Quack.ClientBase {
    
    public func respondAsync<Model: Quack.Model>(method: Quack.HTTP.Method = .get,
                                                 path: String,
                                                 body: [String: Any] = [:],
                                                 headers: [String: String] = [:],
                                                 validStatusCodes: CountableRange<Int> = 200..<300,
                                                 parser: Quack.CustomModelParser? = nil,
                                                 model: Model.Type,
                                                 requestModification: ((Quack.Request) -> (Quack.Request))? = nil,
                                                 completion: @escaping (Quack.Result<Model>) -> (Void)) {
        _respondWithJSONAsync(method: method,
                              path: path,
                              body: body,
                              headers: headers,
                              validStatusCodes: validStatusCodes,
                              requestModification: requestModification) { result in
                                switch result {
                                case .success(let json):
                                    completion((parser ?? self).parseModel(json: json, model: model))
                                case .failure(let error):
                                    completion(Quack.Result.failure(error))
                                }
        }
    }

    public func respondWithArrayAsync<Model: Quack.Model>(method: Quack.HTTP.Method = .get,
                                                         path: String,
                                                         body: [String: Any] = [:],
                                                         headers: [String: String] = [:],
                                                         validStatusCodes: CountableRange<Int> = 200..<300,
                                                         parser: Quack.CustomArrayParser? = nil,
                                                         model: Model.Type,
                                                         requestModification: ((Quack.Request) -> (Quack.Request))? = nil,
                                                         completion: @escaping (Quack.Result<[Model]>) -> (Void)) {
        _respondWithJSONAsync(method: method,
                              path: path,
                              body: body,
                              headers: headers,
                              validStatusCodes: validStatusCodes,
                              requestModification: requestModification) { result in
                                switch result {
                                case .success(let json):
                                    completion((parser ?? self).parseArray(json: json, model: model))
                                case .failure(let error):
                                    completion(Quack.Result.failure(error))
                                }
        }
    }

    public func respondVoidAsync(method: Quack.HTTP.Method = .get,
                                 path: String,
                                 body: [String: Any] = [:],
                                 headers: [String: String] = [:],
                                 validStatusCodes: CountableRange<Int> = 200..<300,
                                 requestModification: ((Quack.Request) -> (Quack.Request))? = nil,
                                 completion: @escaping (Quack.Void) -> (Void)) {
        _respondWithJSONAsync(method: method,
                              path: path,
                              body: body,
                              headers: headers,
                              validStatusCodes: validStatusCodes,
                              requestModification: requestModification) { result in
                                switch result {
                                case .success:
                                    completion(Quack.Result.success(()))
                                case .failure(let error):
                                    completion(Quack.Result.failure(error))
                                }
        }
        
    }
    
}

// MARK: - Path Builder

public extension Quack.ClientBase {
    
    public func buildPath(_ path: String, withParams params: [String: String]) -> String {
        var urlComponents = URLComponents()
        urlComponents.path = path
        
        var queryItems = [URLQueryItem]()
        for (key, value) in params {
            let queryItem = URLQueryItem(name: key, value: value)
            queryItems.append(queryItem)
        }
        urlComponents.queryItems = queryItems
        
        var query = ""
        if let percentEncodedQuery = urlComponents.percentEncodedQuery {
            query = "?\(percentEncodedQuery)"
        }
        return "\(urlComponents.percentEncodedPath)\(query)"
    }
    
}

// MARK: - Response Handling

public extension Quack.ClientBase {

    public func _handleClientResponse(_ response: Quack.Response?,
                                      validStatusCodes: CountableRange<Int>,
                                      completion: @escaping (Quack.Result<JSON>) -> (Void)) {
        guard let response = response else {
            completion(.failure(.errorWithName("No Response")))
            return
        }

        // TODO: Validate response code
        guard validStatusCodes.contains(response.statusCode) else {
            completion(.failure(.invalidStatusCode(response.statusCode)))
            return
        }

        if let bodyString = response.body {
            let json = JSON.parse(string: bodyString)
            completion(.success(json))
        } else {
            completion(.success(JSON()))
        }

    }

}


extension Quack.ClientBase: Quack.CustomModelParser {
    
    public func parseModel<Model>(json: JSON, model: Model.Type) -> Quack.Result<Model> where Model : Quack.Model {
        if let model = Model(json: json) {
            return Quack.Result.success(model)
        } else {
            return Quack.Result.failure(Quack.Error.modelParsingError)
        }
    }
    
}


extension Quack.ClientBase: Quack.CustomArrayParser {
    
    public func parseArray<Model>(json: JSON, model: Model.Type) -> Quack.Result<[Model]> where Model : Quack.Model {
        if let jsonArray = json.array {
            var models: [Model] = []
            for jsonObject in jsonArray {
                if let model = Model(json: jsonObject) {
                    models.append(model)
                }
            }
            return Quack.Result.success(models)
        } else {
            return Quack.Result.failure(Quack.Error.jsonParsingError)
        }
    }
    
}

