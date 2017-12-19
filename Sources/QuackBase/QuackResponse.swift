//
//  QuackResponse.swift
//  QuackBase
//
//  Created by Christoph Pageler on 19.12.17.
//

import Foundation

public extension Quack {
    
    public struct Response {
        
        public var statusCode: Int
        public var body: String? = nil
        
        public init(statusCode: Int, body: String? = nil) {
            self.statusCode = statusCode
            self.body = body
        }
        
    }
}
