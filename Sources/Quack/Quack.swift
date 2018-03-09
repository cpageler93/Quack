//
//  Quack.swift
//  Quack
//
//  Created by Christoph on 16.05.17.
//
//

import Foundation
import Result
import SwiftyJSON
import QuackBase
import Alamofire


extension Quack {
    
    open class Client: ClientBase {
        
        private lazy var manager: Alamofire.SessionManager = {
            [unowned self] in
            
            // Setup Alamofire
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForResource = timeoutInterval
            configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
            
            let manager = Alamofire.SessionManager(configuration: configuration,
                                                   serverTrustPolicyManager: ServerTrustPolicyManager(policies: [:]))
            manager.startRequestsImmediately = false
            
            return manager
            
        }()
        
        open override func _respondWithJSON(method: Quack.HTTP.Method,
                                              path: String,
                                              body: [String : Any],
                                              headers: [String : String],
                                              validStatusCodes: CountableRange<Int>,
                                              requestModification: ((Quack.Request) -> (Quack.Request))?) -> Quack.Result<JSON> {
            let request = dataRequest(method: method,
                                      path: path,
                                      body: body,
                                      headers: headers,
                                      validStatusCodes: validStatusCodes,
                                      requestModification: requestModification)
            let response = request.responseData()
            switch response.result {
            case .success(let jsonData): return .success(JSON(data: jsonData))
            case .failure(let error):    return .failure(.errorWithError(error))
            }
        }
        
        open override func _respondWithJSONAsync(method: Quack.HTTP.Method,
                                                   path: String,
                                                   body: [String: Any],
                                                   headers: [String: String],
                                                   validStatusCodes: CountableRange<Int>,
                                                   requestModification: ((Quack.Request) -> (Quack.Request))?,
                                                   completion: @escaping (Quack.Result<JSON>) -> (Swift.Void)) {
            let request = dataRequest(method: method,
                                      path: path,
                                      body: body,
                                      headers: headers,
                                      validStatusCodes: validStatusCodes,
                                      requestModification: requestModification)
            request.responseData { response in
                switch response.result {
                case .success(let jsonData): completion(.success(JSON(data: jsonData)))
                case .failure(let error):    completion(.failure(.errorWithError(error)))
                }
            }
        }
        
        private func dataRequest(method: Quack.HTTP.Method,
                                 path: String,
                                 body: [String: Any],
                                 headers: [String: String],
                                 validStatusCodes: CountableRange<Int>,
                                 requestModification: ((Quack.Request) -> (Quack.Request))?) -> DataRequest {
            
            // create request
            var request = Quack.Request(method: method,
                                        uri: path,
                                        headers: headers,
                                        body: body)
            
            // allow to modify the request from outside
            if let rmod = requestModification {
                request = rmod(request)
            }
            
            // transform request
            var httpRequest = self.manager.request(url.appendingPathComponent(request.uri),
                                                   method: HTTPMethod(rawValue: request.method.stringValue()) ?? .get,
                                                   parameters: request.body,
                                                   encoding: request.alamofireEncoding(),
                                                   headers: request.headers)
            
            // start reuest
            httpRequest.resume()
            
            // validate request
            httpRequest = httpRequest.validate(statusCode: validStatusCodes)
            
            return httpRequest
        }
        
    }
    
}

extension Quack.Request {
    
    public func alamofireEncoding() -> ParameterEncoding {
        switch encoding {
        case .url: return URLEncoding.default
        case .noUrlEncoding: return NOURLEncoding()
        case .json: return JSONEncoding.default
        }
    }
    
}

internal struct NOURLEncoding: ParameterEncoding {
    
    //protocol implementation
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var urlRequest = try urlRequest.asURLRequest()
        
        guard let parameters = parameters else { return urlRequest }
        
        if HTTPMethod(rawValue: urlRequest.httpMethod ?? "GET") != nil {
            guard let url = urlRequest.url else {
                throw AFError.parameterEncodingFailed(reason: .missingURL)
            }
            
            if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false), !parameters.isEmpty {
                let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + query(parameters)
                urlComponents.percentEncodedQuery = percentEncodedQuery
                urlRequest.url = urlComponents.url
            }
        }
        
        return urlRequest
    }
    
    //append query parameters
    private func query(_ parameters: [String: Any]) -> String {
        var components: [(String, String)] = []
        
        for key in parameters.keys.sorted(by: <) {
            let value = parameters[key]!
            components += queryComponents(fromKey: key, value: value)
        }
        
        return components.map { "\($0)=\($1)" }.joined(separator: "&")
    }
    
    //Alamofire logic for query components handling
    public func queryComponents(fromKey key: String, value: Any) -> [(String, String)] {
        var components: [(String, String)] = []
        
        if let dictionary = value as? [String: Any] {
            for (nestedKey, value) in dictionary {
                components += queryComponents(fromKey: "\(key)[\(nestedKey)]", value: value)
            }
        } else if let array = value as? [Any] {
            for value in array {
                components += queryComponents(fromKey: "\(key)[]", value: value)
            }
        } else if let value = value as? NSNumber {
            if value.isBool {
                components.append((escape(key), escape((value.boolValue ? "1" : "0"))))
            } else {
                components.append((escape(key), escape("\(value)")))
            }
        } else if let bool = value as? Bool {
            components.append((escape(key), escape((bool ? "1" : "0"))))
        } else {
            components.append((escape(key), escape("\(value)")))
        }
        
        return components
    }
    
    //escaping function where we can select symbols which we want to escape
    //(I just removed + for example)
    public func escape(_ string: String) -> String {
        let generalDelimitersToEncode = ":#[]@" // does not include "?" or "/" due to RFC 3986 - Section 3.4
        let subDelimitersToEncode = "!$&'()*,;="
        
        var allowedCharacterSet = CharacterSet.urlQueryAllowed
        allowedCharacterSet.remove(charactersIn: "\(generalDelimitersToEncode)\(subDelimitersToEncode)")
        
        var escaped = ""
        
        escaped = string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? string
        
        return escaped
    }
    
}

extension NSNumber {
    fileprivate var isBool: Bool { return CFBooleanGetTypeID() == CFGetTypeID(self) }
}

