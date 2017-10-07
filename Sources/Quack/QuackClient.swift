//
//  QuackClient.swift
//  Quack
//
//  Created by Christoph on 16.05.17.
//
//

import Foundation
import HTTP
import TLS
import Sockets
import SwiftyJSON
import Dispatch

public enum QuackResult<T> {
    case success(T)
    case failure(Swift.Error)
}

public typealias QuackVoid = QuackResult<Void>

open class QuackClient {
    
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
    
    public func respond<Model: QuackModel>(method: HTTP.Method = .get,
                                           path: String,
                                           body: [String: Any] = [:],
                                           headers: [HeaderKey: String] = [:],
                                           validStatusCodes: CountableRange<Int> = 200..<300,
                                           parser: QuackCustomModelParser? = nil,
                                           model: Model.Type,
                                           requestModification: ((Request) -> (Request))? = nil) -> QuackResult<Model> {
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

    public func respondWithArray<Model: QuackModel>(method: HTTP.Method = .get,
                                                    path: String,
                                                    body: [String: Any] = [:],
                                                    headers: [HeaderKey: String] = [:],
                                                    validStatusCodes: CountableRange<Int> = 200..<300,
                                                    parser: QuackCustomArrayParser? = nil,
                                                    model: Model.Type,
                                                    requestModification: ((Request) -> (Request))? = nil) -> QuackResult<[Model]> {
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
    
    public func respondVoid(method: HTTP.Method = .get,
                            path: String,
                            body: [String: Any] = [:],
                            headers: [HeaderKey: String] = [:],
                            validStatusCodes: CountableRange<Int> = 200..<300,
                            requestModification: ((Request) -> (Request))? = nil) -> QuackVoid {
        let result = respondWithJSON(method: method,
                                     path: path,
                                     body: body,
                                     headers: headers,
                                     validStatusCodes: validStatusCodes,
                                     requestModification: requestModification)
        switch result {
        case .success:
            return QuackResult.success(())
        case .failure(let error):
            return QuackResult.failure(error)
        }
    }
    
    // MARK: - Asynchronous Response
    
    public func respondAsync<Model: QuackModel>(method: HTTP.Method = .get,
                                                path: String,
                                                body: [String: Any] = [:],
                                                headers: [HeaderKey: String] = [:],
                                                validStatusCodes: CountableRange<Int> = 200..<300,
                                                parser: QuackCustomModelParser? = nil,
                                                model: Model.Type,
                                                requestModification: ((Request) -> (Request))? = nil,
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
    
    public func respondWithArrayAsync<Model: QuackModel>(method: HTTP.Method = .get,
                                                         path: String,
                                                         body: [String: Any] = [:],
                                                         headers: [HeaderKey: String] = [:],
                                                         validStatusCodes: CountableRange<Int> = 200..<300,
                                                         parser: QuackCustomArrayParser? = nil,
                                                         model: Model.Type,
                                                         requestModification: ((Request) -> (Request))? = nil,
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
    
    public func respondVoidAsync(method: HTTP.Method = .get,
                                 path: String,
                                 body: [String: Any] = [:],
                                 headers: [HeaderKey: String] = [:],
                                 validStatusCodes: CountableRange<Int> = 200..<300,
                                 requestModification: ((Request) -> (Request))? = nil,
                                 completion: @escaping (QuackVoid) -> (Void)) {
        respondWithJSONAsync(method: method,
                             path: path,
                             body: body,
                             headers: headers,
                             validStatusCodes: validStatusCodes,
                             requestModification: requestModification) { result in
                                switch result {
                                case .success:
                                    completion(QuackResult.success(()))
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
    
    private func respondWithJSON(method: HTTP.Method,
                                 path: String,
                                 body: [String: Any],
                                 headers: [HeaderKey: String],
                                 validStatusCodes: CountableRange<Int>,
                                 requestModification: ((Request) -> (Request))?) -> QuackResult<JSON> {
        
        guard
            let scheme = self.url.scheme,
            let host = self.url.host,
            let httpSocket = try? TCPInternetSocket(scheme: scheme,
                                                    hostname: host,
                                                    port: UInt16(self.url.port ?? 80)),
            var client = try? BasicClient(httpSocket) as Client
        else {
            return QuackResult.failure(QuackError.errorWithName("Failed to setup HTTP Socket"))
        }
        
        if scheme == "https" {
            guard
                let newSocket = try? TCPInternetSocket(scheme: scheme,
                                                       hostname: host,
                                                       port: UInt16(self.url.port ?? 443)),
                let httpsSocket = try? TLS.InternetSocket(newSocket, Context(.client)),
                let httpsClient = try? BasicClient(httpsSocket)
            else {
                return QuackResult.failure(QuackError.errorWithName("Failed to setup HTTPS Socket"))
            }
            client = httpsClient
        }
        
        let version = Version(major: 1, minor: 1)
        var request = Request(method: method,
                              uri: path,
                              version: version,
                              headers: headers,
                              body: Body(JSON(body).rawString() ?? ""))
        
        if let rmod = requestModification {
            request = rmod(request)
        }
        
        guard let response = try? client.respond(to: request) else {
            return QuackResult.failure(QuackError.errorWithName("Failed to respond"))
        }
        
        var result = QuackResult<JSON>.failure(QuackError.errorWithName("Failed handle client response"))
        self.handleClientResponse(response, validStatusCodes: validStatusCodes) { r in
            result = r
        }
        
        return result
    }
    
    private func respondWithJSONAsync(method: HTTP.Method,
                                      path: String,
                                      body: [String: Any],
                                      headers: [HeaderKey: String],
                                      validStatusCodes: CountableRange<Int>,
                                      requestModification: ((Request) -> (Request))?,
                                      completion: @escaping (QuackResult<JSON>) -> (Void)) {
        DispatchQueue.global(qos: .background).async {
            let result = self.respondWithJSON(method: method,
                                              path: path,
                                              body: body,
                                              headers: headers,
                                              validStatusCodes: validStatusCodes,
                                              requestModification: requestModification)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
    
    private func handleClientResponse(_ response: Response?,
                                      validStatusCodes: CountableRange<Int>,
                                      completion: @escaping (QuackResult<JSON>) -> (Void)) {
        guard let response = response else {
            completion(QuackResult.failure(QuackError.errorWithName("No Response")))
            return
        }
        
        // TODO: Validate response code
        guard validStatusCodes.contains(response.status.statusCode) else {
            completion(QuackResult.failure(QuackError.invalidStatusCode(response.status.statusCode)))
            return
        }
        
        if let bodyString = response.body.bytes?.makeString() {
            let json = JSON.parse(string: bodyString)
            completion(QuackResult.success(json))
        } else {
            completion(QuackResult.success(JSON()))
        }
        
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
