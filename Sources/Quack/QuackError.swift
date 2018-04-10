//
//  QuackError.swift
//  Quack
//
//  Created by Christoph Pageler on 18.12.17.
//

import Foundation


public extension Quack {
    
    public struct Error: Swift.Error {
        
        public let type: ErrorType
        public let userInfo: [AnyHashable: Any]
        
        public enum ErrorType {
            
            case modelParsingError
            case jsonParsingError
            case errorWithName(String)
            case errorWithError(Swift.Error)
            case invalidStatusCode(Int)
            case invalidHTTPMethod
            
        }
        
        public static func withType(_ type: ErrorType) -> Quack.Error {
            return Error(type: type, userInfo: [:])
        }
        
    }
    
    public class HTTP {
        
        public enum Method {
            
            case delete
            case get
            case head
            case post
            case put
            case connect
            case options
            case trace
            case patch
            case other(method: String)
            
            public func stringValue() -> String {
                switch self {
                case .delete                : return "DELETE"
                case .get                   : return "GET"
                case .head                  : return "HEAD"
                case .post                  : return "POST"
                case .put                   : return "PUT"
                case .connect               : return "CONNECT"
                case .options               : return "OPTIONS"
                case .trace                 : return "TRACE"
                case .patch                 : return "PATCH"
                case .other(let method)     : return method
                }
            }
        }
        
    }
        
}

