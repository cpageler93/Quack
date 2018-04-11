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
        
        open func _respondWithData(method: Quack.HTTP.Method,
                                   path: String,
                                   body: Quack.Body?,
                                   headers: [String: String],
                                   validStatusCodes: CountableRange<Int>,
                                   requestModification: ((Quack.Request) -> (Quack.Request))?) -> Quack.Result<Data> {
            fatalError("this method must be implemented in subclass")
        }
        
        open func _respondWithDataAsync(method: Quack.HTTP.Method,
                                        path: String,
                                        body: Quack.Body?,
                                        headers: [String: String],
                                        validStatusCodes: CountableRange<Int>,
                                        requestModification: ((Quack.Request) -> (Quack.Request))?,
                                        completion: @escaping (Quack.Result<Data>) -> (Swift.Void)) {
            fatalError("this method must be implemented in subclass")
        }
        
    }
    
}

// MARK: - Synchronous Response

public extension Quack.ClientBase {
    
    public func respond<Model: Quack.DataModel>(method: Quack.HTTP.Method = .get,
                                                path: String,
                                                body: Quack.Body? = nil,
                                                headers: [String: String] = [:],
                                                validStatusCodes: CountableRange<Int> = 200..<300,
                                                parser: Quack.CustomModelParser? = nil,
                                                model: Model.Type,
                                                requestModification: ((Quack.Request) -> (Quack.Request))? = nil) -> Quack.Result<Model> {
        let result = _respondWithData(method: method,
                                      path: path,
                                      body: body,
                                      headers: headers,
                                      validStatusCodes: validStatusCodes,
                                      requestModification: requestModification)
        switch result {
        case .success(let data):
            return (parser ?? self).parseModel(data: data, model: model)
        case .failure(let error):
            return Quack.Result.failure(error)
        }
    }

    public func respondWithArray<Model: Quack.DataModel>(method: Quack.HTTP.Method = .get,
                                                         path: String,
                                                         body: Quack.Body? = nil,
                                                         headers: [String: String] = [:],
                                                         validStatusCodes: CountableRange<Int> = 200..<300,
                                                         parser: Quack.CustomArrayParser? = nil,
                                                         model: Model.Type,
                                                         requestModification: ((Quack.Request) -> (Quack.Request))? = nil) -> Quack.Result<[Model]> {
        let result = _respondWithData(method: method,
                                      path: path,
                                      body: body,
                                      headers: headers,
                                      validStatusCodes: validStatusCodes,
                                      requestModification: requestModification)
        switch result {
        case .success(let data):
            return (parser ?? self).parseArray(data: data, model: model)
        case .failure(let error):
            return Quack.Result.failure(error)
        }
    }

    public func respondVoid(method: Quack.HTTP.Method = .get,
                            path: String,
                            body: Quack.Body? = nil,
                            headers: [String: String] = [:],
                            validStatusCodes: CountableRange<Int> = 200..<300,
                            requestModification: ((Quack.Request) -> (Quack.Request))? = nil) -> Quack.Void {
        let result = _respondWithData(method: method,
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
    
    public func respondAsync<Model: Quack.DataModel>(method: Quack.HTTP.Method = .get,
                                                     path: String,
                                                     body: Quack.Body? = nil,
                                                     headers: [String: String] = [:],
                                                     validStatusCodes: CountableRange<Int> = 200..<300,
                                                     parser: Quack.CustomModelParser? = nil,
                                                     model: Model.Type,
                                                     requestModification: ((Quack.Request) -> (Quack.Request))? = nil,
                                                     completion: @escaping (Quack.Result<Model>) -> (Void)) {
        _respondWithDataAsync(method: method,
                              path: path,
                              body: body,
                              headers: headers,
                              validStatusCodes: validStatusCodes,
                              requestModification: requestModification) { result in
                                switch result {
                                case .success(let data):
                                    completion((parser ?? self).parseModel(data: data, model: model))
                                case .failure(let error):
                                    completion(Quack.Result.failure(error))
                                }
        }
    }

    public func respondWithArrayAsync<Model: Quack.DataModel>(method: Quack.HTTP.Method = .get,
                                                              path: String,
                                                              body: Quack.Body? = nil,
                                                              headers: [String: String] = [:],
                                                              validStatusCodes: CountableRange<Int> = 200..<300,
                                                              parser: Quack.CustomArrayParser? = nil,
                                                              model: Model.Type,
                                                              requestModification: ((Quack.Request) -> (Quack.Request))? = nil,
                                                              completion: @escaping (Quack.Result<[Model]>) -> (Void)) {
        _respondWithDataAsync(method: method,
                              path: path,
                              body: body,
                              headers: headers,
                              validStatusCodes: validStatusCodes,
                              requestModification: requestModification) { result in
                                switch result {
                                case .success(let data):
                                    completion((parser ?? self).parseArray(data: data, model: model))
                                case .failure(let error):
                                    completion(Quack.Result.failure(error))
                                }
        }
    }

    public func respondVoidAsync(method: Quack.HTTP.Method = .get,
                                 path: String,
                                 body: Quack.Body? = nil,
                                 headers: [String: String] = [:],
                                 validStatusCodes: CountableRange<Int> = 200..<300,
                                 requestModification: ((Quack.Request) -> (Quack.Request))? = nil,
                                 completion: @escaping (Quack.Void) -> (Void)) {
        _respondWithDataAsync(method: method,
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
                                      completion: @escaping (Quack.Result<Data>) -> (Void)) {
        guard let response = response else {
            completion(.failure(.withType(.errorWithName("No Response"))))
            return
        }

        guard validStatusCodes.contains(response.statusCode) else {
            let error = Quack.Error(type: .invalidStatusCode(response.statusCode), userInfo: [
                "response": response
            ])
            completion(.failure(error))
            return
        }
        
        completion(.success(response.body ?? Data()))
    }

}


extension Quack.ClientBase: Quack.CustomModelParser {
    
    public func parseModel<Model>(data: Data, model: Model.Type) -> Quack.Result<Model> where Model : Quack.DataModel {
        if let model = Model(data: data) {
            return .success(model)
        } else {
            return .failure(.withType(.modelParsingError))
        }
    }
    
}


extension Quack.ClientBase: Quack.CustomArrayParser {
    
    public func parseArray<Model>(data: Data, model: Model.Type) -> Quack.Result<[Model]> where Model : Quack.DataModel {
        let json = JSON(data: data)
        
        guard let jsonArray = json.array else {
            return .failure(.withType(.jsonParsingError))
        }
        
        var models: [Model] = []
        for jsonObject in jsonArray {
            guard let JSONModel = Model.self as? Quack.Model.Type,
                let jsonModel = JSONModel.init(json: jsonObject),
                let model = jsonModel as? Model
            else {
                continue
            }
            models.append(model)
        }
        return .success(models)
    }
    
}
 
