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
            let completeURL = "\(url)\(request.uri)"
            var httpRequest = self.manager.request(completeURL,
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
        case .json: return JSONEncoding.default
        }
    }
    
}
