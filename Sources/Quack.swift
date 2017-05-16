//
//  Quack.swift
//  Quack
//
//  Created by Christoph on 16.05.17.
//
//

import Foundation

public enum QuackError: Error {
    case ModelParsingError
    case JSONParsingError
    case ErrorWithName(String)
}
