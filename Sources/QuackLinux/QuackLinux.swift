//
//  Quack.swift
//  Quack
//
//  Created by Christoph on 16.05.17.
//
//

import Foundation
@_exported import Result
@_exported import SwiftyJSON
@_exported import QuackBase
@_exported import HTTP
@_exported import Sockets
@_exported import TLS


internal typealias HTTPClient = Client
internal typealias HTTPRequest = Request
internal typealias HTTPMethod = HTTP.Method


extension Quack {
    
    open class Client: ClientBase {
        
        open override func _respondWithData(method: Quack.HTTP.Method,
                                              path: String,
                                              body: [String : Any],
                                              headers: [String : String],
                                              validStatusCodes: CountableRange<Int>,
                                              requestModification: ((Quack.Request) -> (Quack.Request))?) -> Quack.Result<Data> {
            guard
                let scheme = self.url.scheme,
                let host = self.url.host,
                let httpSocket = try? TCPInternetSocket(scheme: scheme,
                                                        hostname: host,
                                                        port: UInt16(self.url.port ?? 80)),
                var client = try? BasicClient(httpSocket) as HTTPClient
            else {
                return .failure(.errorWithName("Failed to setup HTTP Socket"))
            }
    
            if scheme == "https" {
                guard
                    let newSocket = try? TCPInternetSocket(scheme: scheme,
                                                           hostname: host,
                                                           port: UInt16(self.url.port ?? 443)),
                    let httpsSocket = try? TLS.InternetSocket(newSocket, Context(.client)),
                    let httpsClient = try? BasicClient(httpsSocket)
                else {
                    return .failure(.errorWithName("Failed to setup HTTPS Socket"))
                }
                client = httpsClient
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
            var httpHeaders = [HeaderKey: String]()
            for header in request.headers {
                httpHeaders[HeaderKey(header.key)] = header.value
            }
            let httpRequest = HTTPRequest(method: HTTPMethod(request.method.stringValue()),
                                          uri: request.uri,
                                          version: Version(major: 1, minor: 1),
                                          headers: httpHeaders,
                                          body: Body(JSON(request.body ?? [:]).rawString() ?? ""))
    
            // send request
            guard let httpResponse = try? client.respond(to: httpRequest) else {
                return .failure(.errorWithName("Failed to respond"))
            }
    
            // transform response
            let response = Response(statusCode: httpResponse.status.statusCode,
                                    body: Data(bytes: httpResponse.body.bytes ?? []))
            
            var result = Quack.Result<Data>.failure(.errorWithName("Failed handle client response"))
            _handleClientResponse(response, validStatusCodes: validStatusCodes) { r in
                result = r
            }
    
            return result
            
        }
        
        open override func _respondWithDataAsync(method: Quack.HTTP.Method,
                                                 path: String,
                                                 body: [String: Any],
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

