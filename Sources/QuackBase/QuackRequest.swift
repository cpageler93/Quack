//
//  QuackRequest.swift
//  QuackBase
//
//  Created by Christoph Pageler on 18.12.17.
//

import Foundation


public extension Quack {
    
    public struct Request {
        
        public var method: HTTP.Method
        public var uri: String
        public var headers: [String: String]
        public var body: String? = nil
        
        public init(method: HTTP.Method, uri: String, headers: [String: String], body: String) {
            self.method = method
            self.uri = uri
            self.headers = headers
            self.body = body
        }
        
    }
    
}
