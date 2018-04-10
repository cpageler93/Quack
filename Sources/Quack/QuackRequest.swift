//
//  QuackRequest.swift
//  QuackBase
//
//  Created by Christoph Pageler on 18.12.17.
//

import Foundation

#if !os(Linux)
import Alamofire
#endif

public extension Quack {
    
    public struct Request {
        
        public enum Encoding {
            case url
            case json
        }
        
        public var method: HTTP.Method
        public var uri: String
        public var headers: [String: String]
        public var body: [String: Any]? = nil
        public var encoding: Encoding = .url
        
        public init(method: HTTP.Method, uri: String, headers: [String: String], body: [String: Any]) {
            self.method = method
            self.uri = uri
            self.headers = headers
            self.body = body
        }
        
#if !os(Linux)
        public func alamofireEncoding() -> ParameterEncoding {
            switch encoding {
            case .url: return URLEncoding.default
            case .json: return JSONEncoding.default
            }
        }
#endif
        
    }
    
}
