//
//  ConsulQuack.swift
//  Quack
//
//  Created by Christoph Pageler on 25.05.17.
//
//

import Foundation
import SwiftyJSON
import HTTP

@testable import QuackBase
@testable import QuackLinux


public class ConsulAgentCheckOutput: Quack.Model {
    
    var node: String
    var checkID: String

    required public init?(json: JSON) {
        guard
            let node = json["Node"].string,
            let checkID = json["CheckID"].string else { return nil }
        self.node = node
        self.checkID = checkID
    }

}


public class ConsulKeyValuePair: Quack.Model {
    
    var key: String
    var value: String
    
    public required init?(json: JSON) {
        guard
            let jsonArray = json.array,
            let firstJsonEntry = jsonArray.first,
            let key = firstJsonEntry["Key"].string,
            let value = firstJsonEntry["Value"].string
            else { return nil }
        
        self.key = key
        self.value = value
    }
    
    public func decodedValue() -> String? {
        guard let decodedData = Data(base64Encoded: value) else { return nil }
        return String(data: decodedData, encoding: String.Encoding.utf8)
    }
    
}


public class Consul: Quack.Client {

    public init() {
        super.init(url: URL(string: "http://localhost:8500")!)
    }
    
    public func agentReload() -> Quack.Void {
        return respondVoid(method: .put, path: "/v1/agent/reload")
    }
    
    public func agentChecks() -> Quack.Result<[ConsulAgentCheckOutput]> {
        return respondWithArray(path: "/v1/agent/checks",
                                parser: Quack.ArrayParserByIgnoringDictionaryKeys(),
                                model: ConsulAgentCheckOutput.self)
    }
    
    public func readKey(_ key: String) -> Quack.Result<ConsulKeyValuePair> {
        return respond(path: "/v1/kv/\(key)",
            model: ConsulKeyValuePair.self)
    }
    
    public func writeKey(_ key: String,
                         value: String) -> Quack.Result<Bool> {
        return respond(method: .put,
                       path: buildPath("/v1/kv/\(key)", withParams: ["dc" : "fra1"]),
                       model: Bool.self,
                       requestModification: { (request) -> (Quack.Request) in
                        var newRequest = request
                        newRequest.body = value
                        return newRequest
        })
    }
    
}


extension Consul {
    
    public func appendPath(_ path: String,
                           withURLParams params: [String: String?]) -> String {
        guard var urlComponents = URLComponents(string: path) else { return path }
        var queryItems: [URLQueryItem] = urlComponents.queryItems ?? []
        params.forEach { key, value in
            let queryItem = URLQueryItem(name: key, value: value)
            queryItems.append(queryItem)
        }
        urlComponents.queryItems = queryItems
        if queryItems.count > 0, let encodedQuery = urlComponents.percentEncodedQuery {
            return "\(urlComponents.path)?\(encodedQuery)"
        } else {
            return urlComponents.path
        }
    }
    
}


extension Bool: Quack.Model {
    
    public init?(json: JSON) {
        guard let bool = json.bool else { return nil }
        self.init(bool)
    }
    
}

