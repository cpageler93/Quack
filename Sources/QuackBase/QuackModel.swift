//
//  QuackModel.swift
//  Quack
//
//  Created by Christoph on 16.05.17.
//
//

import Foundation
import SwiftyJSON


public extension Quack {
    
    public typealias DataModel = _QuackDataModel
    public typealias Model = _QuackModel
    
}


public protocol _QuackDataModel {
    
    init?(data: Data)
    
}


public protocol _QuackModel: _QuackDataModel {
    
    init?(json: JSON)
    
}


extension _QuackModel {
    
    public init?(data: Data) {
        self.init(json: JSON(data: data))
    }
    
}
