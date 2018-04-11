//
//  QuackBody.swift
//  Quack
//
//  Created by Christoph Pageler on 11.04.18.
//


public protocol _QuackBody { }


public extension Quack {

    public typealias Body = _QuackBody
    
    public struct StringBody: Quack.Body {
        
        public var string: String
        
        public init(_ string: String) {
            self.string = string
        }
        
    }
    
    public struct JSONBody: Quack.Body {
        
        public var json: [String: Any]
        
        public init(_ json: [String: Any]) {
            self.json = json
        }
        
    }
    
}
