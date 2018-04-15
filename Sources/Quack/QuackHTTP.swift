//
//  QuackHTTP.swift
//  Quack
//
//  Created by Christoph on 16.05.17.
//
//

#if os(Linux)

import Foundation
import Result
import SwiftyJSON
import HTTP


extension Quack {
    
    open class Client: ClientBase {
        
        open override func _respondWithData(method: Quack.HTTP.Method,
                                              path: String,
                                              body: Quack.Body?,
                                              headers: [String : String],
                                              validStatusCodes: CountableRange<Int>,
                                              requestModification: ((Quack.Request) -> (Quack.Request))?) -> Quack.Result<Data> {
            guard let scheme = self.url.scheme,
                let host = self.url.host
            else {
                return .failure(.withType(.errorWithName("Failed to setup HTTP Socket")))
            }
            
            // setup http client
            let loop = MultiThreadedEventLoopGroup(numThreads: 1).next()
            let httpClient: EventLoopFuture<HTTPClient>
            if scheme == "https" {
                do {
                    httpClient = try HTTPClient.connectWithTLS(hostname: host, port: url.port ?? 443, on: loop)
                } catch let error {
                    return .failure(.withType(.errorWithError(error)))
                }
            } else {
                httpClient = HTTPClient.connect(hostname: host, port: url.port ?? 80, on: loop)
            }
    
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
            var httpRequest = HTTPRequest(method: HTTPMethod.RAW(value: request.method.stringValue()),
                                          url: URL(string: path)!)
            httpRequest.headers.replaceOrAdd(name: .host, value: host)
            httpRequest.headers.replaceOrAdd(name: .userAgent, value: "Quack")
            
            for header in request.headers {
                httpRequest.headers.replaceOrAdd(name: header.key, value: header.value)
            }
            
            switch body {
            case let stringBody as StringBody:
                httpRequest.body = HTTPBody(string: stringBody.string)
                break
            case let jsonBody as JSONBody:
                httpRequest.body = HTTPBody(string: JSON(jsonBody.json).rawString() ?? "")
                break
            default:
                break
            }
            
            let g = DispatchGroup()
            g.enter()
            var result = Quack.Result<Data>.failure(.withType(.errorWithName("Failed handle client response")))
            httpClient.flatMap(to: HTTPResponse.self) { client in
                client.respond(to: httpRequest, on: loop)
            }.do { httpResponse in
                // transform response
                let response = Response(statusCode: Int(httpResponse.status.code),
                                        body: httpResponse.body.data)
                
                self._handleClientResponse(response, validStatusCodes: validStatusCodes) { r in
                    result = r
                    g.leave()
                }
            }.catch { error in
                result = .failure(.withType(.errorWithError(error)))
                g.leave()
            }
            
            g.wait()
            return result
            
        }
        
        open override func _respondWithDataAsync(method: Quack.HTTP.Method,
                                                 path: String,
                                                 body: Quack.Body?,
                                                 headers: [String: String],
                                                 validStatusCodes: CountableRange<Int>,
                                                 requestModification: ((Quack.Request) -> (Quack.Request))?,
                                                 completion: @escaping (Quack.Result<Data>) -> (Swift.Void)) {
            DispatchQueue.global(qos: .background).async {
                let result = self._respondWithData(method: method,
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
        
    }
    
}

#endif
