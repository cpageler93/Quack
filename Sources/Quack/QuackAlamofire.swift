//
//  QuackAlamofire.swift
//  Quack
//
//  Created by Christoph Pageler on 10.04.18.
//

#if !os(Linux)


import Foundation
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
        
        open override func _respondWithData(method: Quack.HTTP.Method,
                                            path: String,
                                            body: Quack.Body?,
                                            headers: [String : String],
                                            validStatusCodes: CountableRange<Int>,
                                            requestModification: ((Quack.Request) -> (Quack.Request))?) -> Quack.Result<Data> {
            let request = dataRequest(method: method,
                                      path: path,
                                      body: body,
                                      headers: headers,
                                      validStatusCodes: validStatusCodes,
                                      requestModification: requestModification)
            let response = request.responseData()
            let result = convertResponseToResult(response, validStatusCodes: validStatusCodes)
            
            return result
        }
        
        open override func _respondWithDataAsync(method: Quack.HTTP.Method,
                                                 path: String,
                                                 body: Quack.Body?,
                                                 headers: [String: String],
                                                 validStatusCodes: CountableRange<Int>,
                                                 requestModification: ((Quack.Request) -> (Quack.Request))?,
                                                 completion: @escaping (Quack.Result<Data>) -> (Swift.Void)) {
            let request = dataRequest(method: method,
                                      path: path,
                                      body: body,
                                      headers: headers,
                                      validStatusCodes: validStatusCodes,
                                      requestModification: requestModification)
            
            request.responseData { response in
                let result = self.convertResponseToResult(response, validStatusCodes: validStatusCodes)
                completion(result)
            }
        }
        
        private func dataRequest(method: Quack.HTTP.Method,
                                 path: String,
                                 body: Quack.Body?,
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
            
            // transform request to alamofire
            let completeURL = "\(url)\(request.uri)"
            
            var encoding = request.alamofireEncoding()
            var parameters: Parameters = [:]

            let httpRequest: DataRequest

            switch body {
            case let dataBody as DataBody:
                httpRequest = self.manager.upload(dataBody.data,
                                                  to: completeURL,
                                                  method: HTTPMethod(rawValue: request.method.stringValue()) ?? .get,
                                                  headers: request.headers)
            case let stringBody as StringBody:
                encoding = stringBody.string
                httpRequest =  self.manager.request(completeURL,
                                                    method: HTTPMethod(rawValue: request.method.stringValue()) ?? .get,
                                                    parameters: parameters,
                                                    encoding: encoding,
                                                    headers: request.headers)
                break
            case let jsonBody as JSONBody:
                parameters = jsonBody.json
                httpRequest =  self.manager.request(completeURL,
                                                    method: HTTPMethod(rawValue: request.method.stringValue()) ?? .get,
                                                    parameters: parameters,
                                                    encoding: encoding,
                                                    headers: request.headers)
                break
            default:
                abort()
            }
            
            // start reuest
            httpRequest.resume()
            
            return httpRequest
        }
        
        private func convertResponseToResult(_ dataResponse: DataResponse<Data>,
                                             validStatusCodes: CountableRange<Int>) -> Quack.Result<Data> {
            if let error = dataResponse.error {
                return .failure(.withType(.errorWithError(error)))
            }
            var result = Quack.Result<Data>.failure(.withType(.errorWithName("Failed handle client response")))
            guard let statusCode = dataResponse.response?.statusCode else {
                return result
            }
            
            // transform response
            let response = Response(statusCode: statusCode,
                                    body: dataResponse.data)
            
            self._handleClientResponse(response, validStatusCodes: validStatusCodes, completion: { r in
                result = r
            })
            
            return result
        }
        
    }
    
}

extension String: ParameterEncoding {
    
    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.httpBody = data(using: .utf8, allowLossyConversion: false)
        return request
    }
    
}

#endif
