//
//  DummyAccountService.swift
//  Quack
//
//  Created by Christoph Pageler on 25.05.17.
//
//

import Foundation
import Quack


class DummyAccountServiceClient: Quack.Client {

    func getVoid() -> Quack.Void {
        return respondVoid(path: "foo/bar")
    }

    func getVoid(completion: @escaping (Quack.Void) -> (Void)) {
        respondVoidAsync(path: "foo/bar", completion: completion)
    }

}
