# Quack

**UNDER HEAVY CONSTRUCTION**

## Example

### Code to define a Service

```swift
class GithubClient: QuackClient {
    init() {
       super.init(url: URL(string: "https://api.github.com")!)
    }

    // synchronous
    public func repositories(owner: String) -> QuackResult<[GithubRepository]> {
        return respondWithArray(method: .get,
                                path: "/users/\(owner)/repos",
                                model: GithubRepository.self)
    }

    // asynchronous
    public func repositories(owner: String, completion: @escaping (QuackResult<[GithubRepository]>) -> (Void)) {
        return respondWithArrayAsync(method: .get,
                                     path: "/users/\(owner)/repos",
                                     model: GithubRepository.self,
                                     completion: completion)
    }
}

class GithubRepository: QuackModel {
    var name: String?
    var fullName: String?
    var owner: String?

    required init?(json: JSON) {
        self.name = json["name"].string
        self.fullName = json["full_name"].string
        self.owner = json["owner"]["login"].string
    }
}
```

#### Code to call a service

```swift
let github = GithubClient()

// synchronous
let repos = github.repositories(owner: "cpageler93")
switch repos {
case .Success(let repos):
    // do something with repos (which is kind of [GithubRepository])
case .Failure(let error):
    // handle error
}


// asynchronous
github.repositories(owner: "cpageler93") { repos in
    switch repos {
    case .Success(let repos):
        // do something with repos (which is kind of [GithubRepository])
    case .Failure(let error):
        // handle error
    }
}

```
