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
    
    public typealias Model = _QuackModel
    
}


public protocol _QuackModel {
    
    init?(json: JSON)
    
}
