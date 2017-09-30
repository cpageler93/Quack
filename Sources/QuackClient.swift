//
//  QuackClient.swift
//  Quack
//
//  Created by Christoph on 16.05.17.
//
//

import Foundation
import KituraNet
import SwiftyJSON
import Dispatch

public enum QuackResult<T> {
    case success(T)
    case failure(Swift.Error)
}

public typealias QuackVoid = QuackResult<Void>

open class QuackClient {
    
    public enum HTTPMethod: String {
        case get
        case post
        case patch
        case put
        case delete
    }

    public private(set) var url: URL
    
    // MARK: - Init

    public init(url: URL,
                timeoutInterval: TimeInterval = 5) {
        self.url = url
    }

    convenience public init?(urlString: String,
                             timeoutInterval: TimeInterval = 5) {
       if let url = URL(string: urlString) {
            self.init(url: url, timeoutInterval: timeoutInterval)
       } else {
         return nil
       }
    }
    
    // MARK: - Synchronous Response
    
    public func respond<Model: QuackModel>(method: HTTPMethod = .get,
                                           path: String,
                                           body: [String: Any] = [:],
                                           headers: [String: String] = [:],
                                           validStatusCodes: CountableRange<Int> = 200..<300,
                                           parser: QuackCustomModelParser? = nil,
                                           model: Model.Type,
                                           requestModification: ((ClientRequest) -> (ClientRequest))? = nil) -> QuackResult<Model> {
        let result = respondWithJSON(method: method,
                                     path: path,
                                     body: body,
                                     headers: headers,
                                     validStatusCodes: validStatusCodes,
                                     requestModification: requestModification)
        switch result {
        case .success(let json):
            return (parser ?? self).parseModel(json: json, model: model)
        case .failure(let error):
            return QuackResult.failure(error)
        }
    }

    public func respondWithArray<Model: QuackModel>(method: HTTPMethod = .get,
                                                    path: String,
                                                    body: [String: Any] = [:],
                                                    headers: [String: String] = [:],
                                                    validStatusCodes: CountableRange<Int> = 200..<300,
                                                    parser: QuackCustomArrayParser? = nil,
                                                    model: Model.Type,
                                                    requestModification: ((ClientRequest) -> (ClientRequest))? = nil) -> QuackResult<[Model]> {
        let result = respondWithJSON(method: method,
                                     path: path,
                                     body: body,
                                     headers: headers,
                                     validStatusCodes: validStatusCodes,
                                     requestModification: requestModification)
        switch result {
        case .success(let json):
            return (parser ?? self).parseArray(json: json, model: model)
        case .failure(let error):
            return QuackResult.failure(error)
        }
    }
    
    public func respondVoid(method: HTTPMethod = .get,
                            path: String,
                            body: [String: Any] = [:],
                            headers: [String: String] = [:],
                            validStatusCodes: CountableRange<Int> = 200..<300,
                            requestModification: ((ClientRequest) -> (ClientRequest))? = nil) -> QuackVoid {
        let result = respondWithJSON(method: method,
                                     path: path,
                                     body: body,
                                     headers: headers,
                                     validStatusCodes: validStatusCodes,
                                     requestModification: requestModification)
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
                                                body: [String: Any] = [:],
                                                headers: [String: String] = [:],
                                                validStatusCodes: CountableRange<Int> = 200..<300,
                                                parser: QuackCustomModelParser? = nil,
                                                model: Model.Type,
                                                requestModification: ((ClientRequest) -> (ClientRequest))? = nil,
                                                completion: @escaping (QuackResult<Model>) -> (Void)) {
        respondWithJSONAsync(method: method,
                             path: path,
                             body: body,
                             headers: headers,
                             validStatusCodes: validStatusCodes,
                             requestModification: requestModification) { result in
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
                                                         body: [String: Any] = [:],
                                                         headers: [String: String] = [:],
                                                         validStatusCodes: CountableRange<Int> = 200..<300,
                                                         parser: QuackCustomArrayParser? = nil,
                                                         model: Model.Type,
                                                         requestModification: ((ClientRequest) -> (ClientRequest))? = nil,
                                                         completion: @escaping (QuackResult<[Model]>) -> (Void)) {
        respondWithJSONAsync(method: method,
                             path: path,
                             body: body,
                             headers: headers,
                             validStatusCodes: validStatusCodes,
                             requestModification: requestModification) { result in
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
                                 body: [String: Any] = [:],
                                 headers: [String: String] = [:],
                                 validStatusCodes: CountableRange<Int> = 200..<300,
                                 requestModification: ((ClientRequest) -> (ClientRequest))? = nil,
                                 completion: @escaping (QuackVoid) -> (Void)) {
        respondWithJSONAsync(method: method,
                             path: path,
                             body: body,
                             headers: headers,
                             validStatusCodes: validStatusCodes,
                             requestModification: requestModification) { result in
                                switch result {
                                case .success:
                                    completion(QuackResult.success())
                                case .failure(let error):
                                    completion(QuackResult.failure(error))
                                }
        }
    }
    
    // MARK: - Path Builder
    
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
    
    // MARK: - Alamofire Requests
    
    private func respondWithJSON(method: HTTPMethod,
                                 path: String,
                                 body: [String: Any],
                                 headers: [String: String],
                                 validStatusCodes: CountableRange<Int>,
                                 requestModification: ((ClientRequest) -> (ClientRequest))?) -> QuackResult<JSON> {
        var response: ClientResponse? = nil
        
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        self.dataRequest(method: method,
                         path: path,
                         body: body,
                         headers: headers,
                         validStatusCodes: validStatusCodes,
                         requestModification: requestModification)
        { r in
            response = r
            dispatchGroup.leave()
        }
        dispatchGroup.wait()
        
        var result = QuackResult<JSON>.failure(QuackError.errorWithName("Failed handle client response"))
        self.handleClientResponse(response, validStatusCodes: validStatusCodes) { r in
            result = r
        }
        
        return result
    }
    
    private func respondWithJSONAsync(method: HTTPMethod,
                                      path: String,
                                      body: [String: Any],
                                      headers: [String: String],
                                      validStatusCodes: CountableRange<Int>,
                                      requestModification: ((ClientRequest) -> (ClientRequest))?,
                                      completion: @escaping (QuackResult<JSON>) -> (Void)) {
        dataRequest(method: method,
                    path: path,
                    body: body,
                    headers: headers,
                    validStatusCodes: validStatusCodes,
                    requestModification: requestModification)
        { response in
            self.handleClientResponse(response, validStatusCodes: validStatusCodes, completion: completion)
        }
    }
    
    private func handleClientResponse(_ response: ClientResponse?,
                                      validStatusCodes: CountableRange<Int>,
                                      completion: @escaping (QuackResult<JSON>) -> (Void)) {
        guard let response = response else {
            completion(QuackResult.failure(QuackError.errorWithName("No Response")))
            return
        }
        
        // TODO: Validate response code
        guard validStatusCodes.contains(response.status) else {
            completion(QuackResult.failure(QuackError.invalidStatusCode(response.status)))
            return
        }
        
        var responseData = Data()
        do {
            try response.readAllData(into: &responseData)
            guard let responseString = String(data: responseData, encoding: String.Encoding.utf8) else {
                completion(QuackResult.failure(QuackError.jsonParsingError))
                return
            }
            let json = JSON.parse(string: responseString)
            completion(QuackResult.success(json))
        } catch {
            completion(QuackResult.failure(QuackError.jsonParsingError))
        }
    }
    
    @discardableResult
    private func dataRequest(method: HTTPMethod,
                             path: String,
                             body: [String: Any],
                             headers: [String: String],
                             validStatusCodes: CountableRange<Int>,
                             requestModification: ((ClientRequest) -> (ClientRequest))?,
                             callback: @escaping ClientRequest.Callback) -> ClientRequest {
        // create request
        let url = self.url.appendingPathComponent(path)
        
        var request = HTTP.request(url.absoluteString, callback: callback)
        if
            let scheme = url.scheme,
            let host = url.host,
            let port = url.port
        {
            request = HTTP.request([
                ClientRequest.Options.method(method.rawValue),
                ClientRequest.Options.schema(scheme),
                ClientRequest.Options.hostname(host),
                ClientRequest.Options.port(Int16(port)),
                ClientRequest.Options.path(url.path)
            ], callback: callback)
        }
        
        request.headers = headers

        // allow to modify when modification block was passed
        if let requestModification = requestModification {
            request = requestModification(request)
        }
        
        // write json to request body
        do {
            if body.count > 0 {
                let json = JSON(body)
                let data = try json.rawData()
                request.write(from: data)
            }
        } catch {
            
        }
        
        request.end()
        
        return request
    }
    
}

extension QuackClient: QuackCustomModelParser {
    
    public func parseModel<Model>(json: JSON, model: Model.Type) -> QuackResult<Model> where Model : QuackModel {
        if let model = Model(json: json) {
            return QuackResult.success(model)
        } else {
            return QuackResult.failure(QuackError.modelParsingError)
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
            return QuackResult.failure(QuackError.jsonParsingError)
        }
    }
    
}
