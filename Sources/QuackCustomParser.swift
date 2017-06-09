//
//  QuackCustomParser.swift
//  Quack
//
//  Created by Christoph on 26.05.17.
//
//

import Foundation
import SwiftyJSON

public protocol QuackCustomArrayParser {
    func parseArray<Model: QuackModel>(json: JSON, model: Model.Type) -> QuackResult<[Model]>
}

public protocol QuackCustomModelParser {
    func parseModel<Model: QuackModel>(json: JSON, model: Model.Type) -> QuackResult<Model>
}


/// QuackArrayParserByIgnoringDictionaryKeys
///
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
open class QuackArrayParserByIgnoringDictionaryKeys {

    public init() {}

}

extension QuackArrayParserByIgnoringDictionaryKeys: QuackCustomArrayParser {

    public func parseArray<Model>(json: JSON, model: Model.Type) -> QuackResult<[Model]> where Model : QuackModel {
        if let dictionary = json.dictionary {
            var result: [Model] = []
            for (_, value) in dictionary {
                if let model = Model(json: value) {
                    result.append(model)
                }
            }
            return QuackResult.success(result)
        }
        
        return QuackResult.failure(QuackError.JSONParsingError)
    }
    
}
