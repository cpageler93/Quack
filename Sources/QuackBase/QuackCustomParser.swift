//
//  QuackCustomParser.swift
//  Quack
//
//  Created by Christoph on 26.05.17.
//
//

import Foundation
import SwiftyJSON


public extension Quack {
    
    public typealias CustomArrayParser = _QuackCustomArrayParser
    public typealias CustomModelParser = _QuackCustomModelParser
    
}


public protocol _QuackCustomArrayParser {
    
    func parseArray<Model: Quack.Model>(json: JSON, model: Model.Type) -> Quack.Result<[Model]>
    
}


public protocol _QuackCustomModelParser {
    
    func parseModel<Model: Quack.Model>(json: JSON, model: Model.Type) -> Quack.Result<Model>
    
}

// MARK: - QuackArrayParserByIgnoringDictionaryKeys

public extension Quack {
    
    
    /// Parses dictionaries:
    /// {
    ///   "foo": {
    ///     "attr1": "foo",
    ///     "attr2": "bar",
    ///     "attr3": "baz",
    ///   },
    ///   "bar": {
    ///     "attr1": "bar",
    ///     "attr2": "foo",
    ///     "attr3": "baz",
    ///   }
    /// }
    ///
    /// to arrays (by ignoring the keys):
    /// [
    ///   {
    ///     "attr1": "foo",
    ///     "attr2": "bar",
    ///     "attr3": "baz",
    ///   },
    ///   {
    ///     "attr1": "bar",
    ///     "attr2": "foo",
    ///     "attr3": "baz",
    ///   }
    /// ]
    public class ArrayParserByIgnoringDictionaryKeys {
        
        public init() {}
        
    }
    
}

// MARK: - Quack.CustomArrayParser

extension Quack.ArrayParserByIgnoringDictionaryKeys: Quack.CustomArrayParser {

    public func parseArray<Model>(json: JSON, model: Model.Type) -> Quack.Result<[Model]> where Model : Quack.Model {
        if let dictionary = json.dictionary {
            var result: [Model] = []
            for (_, value) in dictionary {
                if let model = Model(json: value) {
                    result.append(model)
                }
            }
            return Quack.Result.success(result)
        }

        return Quack.Result.failure(Quack.Error.jsonParsingError)
    }

}

