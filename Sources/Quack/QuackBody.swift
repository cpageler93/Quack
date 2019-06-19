//
//  QuackBody.swift
//  Quack
//
//  Created by Christoph Pageler on 11.04.18.
//


import Foundation


public protocol _QuackBody { }


public extension Quack {

    typealias Body = _QuackBody
    
    struct StringBody: Quack.Body {
        
        public var string: String
        
        public init(_ string: String) {
            self.string = string
        }
        
    }
    
    struct JSONBody: Quack.Body {
        
        public var json: [String: Any]
        
        public init(_ json: [String: Any]) {
            self.json = json
        }
        
    }

    struct DataBody: Quack.Body {

        public var data: Data

        public init(_ data: Data) {
            self.data = data
        }

    }
    
}
