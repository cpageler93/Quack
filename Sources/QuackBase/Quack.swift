//
//  Quack.swift
//  Quack
//
//  Created by Christoph on 16.05.17.
//
//

import Foundation
import Result


open class Quack {
    
    public typealias Result = _QuackResult
    public typealias Void = _QuackVoid

}


public typealias _QuackResult<T> = Result<T, Quack.Error>
public typealias _QuackVoid = _QuackResult<Void>
