//
//  ConsulQuack.swift
//  Quack
//
//  Created by Christoph Pageler on 25.05.17.
//
//

import Foundation
import Quack

public class Consul: QuackClient {
    
    public init() {
        super.init(url: URL(string: "http://localhost:8500")!)
    }
    
    public func agentReload() -> QuackVoid {
        return respondVoid(path: "/v1/agent/reload")
    }
    
}
