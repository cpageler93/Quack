//
//  QuackResponse.swift
//  QuackBase
//
//  Created by Christoph Pageler on 19.12.17.
//

import Foundation


public extension Quack {
    
    struct Response {
        
        public var statusCode: Int
        public var body: Data? = nil
        
        public init(statusCode: Int, body: Data? = nil) {
            self.statusCode = statusCode
            self.body = body
        }
        
    }
}
