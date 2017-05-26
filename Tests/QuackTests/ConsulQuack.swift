//
//  ConsulQuack.swift
//  Quack
//
//  Created by Christoph Pageler on 25.05.17.
//
//

import Foundation
import SwiftyJSON
@testable import Quack

public class ConsulAgentCheckOutput: QuackModel {
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

public class Consul: QuackClient {
    
    public init() {
        super.init(url: URL(string: "http://localhost:8500")!)
    }
    
    public func agentReload() -> QuackVoid {
        return respondVoid(method: .put, path: "/v1/agent/reload")
    }
    
    public func agentChecks() -> QuackResult<[ConsulAgentCheckOutput]> {
        let parser = QuackCustomDictionaryParser()
        return respondWithArray(path: "/v1/agent/checks",
                                parser: parser,
                                model: ConsulAgentCheckOutput.self)
    }
    
}
