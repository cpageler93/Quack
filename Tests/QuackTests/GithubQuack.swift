import Foundation
import SwiftyJSON
@testable import Quack

class GithubClient: QuackClient {

    init() {
       super.init(url: URL(string: "https://api.github.com")!)
    }

    // MARK: - Repository Methods

    public func repositories(owner: String) -> QuackResult<[GithubRepository]> {
        return respondWithArray(method: .get,
                                path: "/users/\(owner)/repos",
                                headers: ["User-Agent": "Quack-Client"],
                                model: GithubRepository.self)
    }

    public func repositories(owner: String, completion: @escaping (QuackResult<[GithubRepository]>) -> (Void)) {
        return respondWithArrayAsync(method: .get,
                                     path: "/users/\(owner)/repos",
                                     headers: ["User-Agent": "Quack-Client"],
                                     model: GithubRepository.self,
                                     completion: completion)
    }

    public func repositoryBranches(repository: GithubRepository) -> QuackResult<[GithubRepositoryBranch]> {
        guard let fullName = repository.fullName else {
            return QuackResult.failure(QuackError.errorWithName("missing fullname"))
        }
        return respondWithArray(method: .get,
                                path: "/repos/\(fullName)/branches",
                                headers: ["User-Agent": "Quack-Client"],
                                model: GithubRepositoryBranch.self)
    }

}

class GithubRepository: QuackModel {
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

class GithubRepositoryBranch: QuackModel {
    var name: String?
    
    required init?(json: JSON) {
        self.name = json["name"].string
    }
}
