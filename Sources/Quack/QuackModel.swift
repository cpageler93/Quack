//
//  QuackModel.swift
//  Quack
//
//  Created by Christoph on 16.05.17.
//
//

import Foundation
import SwiftyJSON

public protocol QuackModel {
    init?(json: JSON)
}
