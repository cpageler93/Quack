//
//  GithubQuack.swift
//  Quack
//
//  Created by Christoph Pageler on 25.05.17.
//
//

import Foundation
import SwiftyJSON
@testable import Quack


class GithubClient: Quack.Client {

    init() {
       super.init(url: URL(string: "https://api.github.com")!)
    }

    // MARK: - Repository Methods

    public func repositories(owner: String) -> Quack.Result<[GithubRepository]> {
        return respondWithArray(method: .get,
                                path: "/users/\(owner)/repos",
                                headers: ["User-Agent": "Quack-Client"],
                                model: GithubRepository.self)
    }

    public func repositories(owner: String,
                             completion: @escaping (Quack.Result<[GithubRepository]>) -> (Void)) {
        return respondWithArrayAsync(method: .get,
                                     path: "/users/\(owner)/repos",
                                     headers: ["User-Agent": "Quack-Client"],
                                     model: GithubRepository.self,
                                     completion: completion)
    }

    public func repositoryBranches(repository: GithubRepository) -> Quack.Result<[GithubRepositoryBranch]> {
        guard let fullName = repository.fullName else {
            return .failure(.errorWithName("missing fullname"))
        }
        return respondWithArray(method: .get,
                                path: "/repos/\(fullName)/branches",
                                headers: ["User-Agent": "Quack-Client"],
                                model: GithubRepositoryBranch.self)
    }

}


class GithubRepository: Quack.Model {
    
    var name: String?
    var fullName: String?
    var owner: String?

    init(_ fullName: String) {
        self.fullName = fullName
    }
    
    required init?(json: JSON) {
        self.name = json["name"].string
        self.fullName = json["full_name"].string
        self.owner = json["owner"]["login"].string
    }
    
}


class GithubRepositoryBranch: Quack.Model {
    
    var name: String?
    
    required init?(json: JSON) {
        self.name = json["name"].string
    }
    
}
