# Quack

[![Codacy Badge](https://api.codacy.com/project/badge/Grade/28beba3fed654a6284a1fca5df022490)](https://www.codacy.com/app/cpageler93/Quack?utm_source=github.com&utm_medium=referral&utm_content=cpageler93/Quack&utm_campaign=badger)
![Platforms](https://img.shields.io/badge/Platforms-iOS|macOS|tvOS|watchOS|Linux-yellow.svg?style=flat)
[![License](https://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/cpageler93/Quack/blob/master/LICENSE)
[![Twitter: @cpageler93](https://img.shields.io/badge/contact-@cpageler93-lightgrey.svg?style=flat)](https://twitter.com/cpageler93)


`Quack` is an easy to use HTTP Client.

With `Quack` HTTP calls look that beautiful and easy:

```swift
let github = GithubClient()

github.repositories(owner: "cpageler93") { repos in
    switch repos {
    case .success(let repos):
        // do something with repos (which is kind of [GithubRepository])
    case .failure(let error):
        // handle error
    }
}
```

## Usage

### Base Classes

- `QuackClient` methods to make via HTTP
- `QuackModel` parsing JSON to models

### Code to define a Service

```swift
class GithubClient: Quack.Client {

    init() {
       super.init(url: URL(string: "https://api.github.com")!)
    }

    // synchronous
    public func repositories(owner: String) -> Quack.Result<[GithubRepository]> {
        return respondWithArray(path: "/users/\(owner)/repos",
                                model: GithubRepository.self)
    }

    // asynchronous
    public func repositories(owner: String, completion: @escaping (Quack.Result<[GithubRepository]>) -> (Void)) {
        return respondWithArrayAsync(path: "/users/\(owner)/repos",
                                     model: GithubRepository.self,
                                     completion: completion)
    }

}

class GithubRepository: Quack.Model {

    let name: String?
    let fullName: String?
    let owner: String?

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
case .success(let repos):
    // do something with repos (which is kind of [GithubRepository])
case .failure(let error):
    // handle error
}


// asynchronous
github.repositories(owner: "cpageler93") { repos in
    switch repos {
    case .success(let repos):
        // do something with repos (which is kind of [GithubRepository])
    case .failure(let error):
        // handle error
    }
}

```

### Tests

Some tests are based on a local consul service. So start consul at first.

```
consul agent --dev --datacenter fra1
```

## Need Help?

Please [submit an issue](https://github.com/cpageler93/quack/issues) on GitHub or contact me via Mail or Twitter.

## License

This project is licensed under the terms of the MIT license. See the [LICENSE](LICENSE) file.
