# Quack

**UNDER HEAVY CONSTRUCTION**

## Example

### Code to define a Service

	class GithubClient: QuackClient {
		init() {
			super.init(url: URL(string: "https://api.github.com")!)
		}
	
	    public func repositories(owner: String) -> [GithubRepository]? {
	        return respondWithArray(method: .get,
	                                path: "/users/\(owner)/repos",
	                                model: GithubRepository.self)
		}
	}
	
	class GithubRepository: QuackModel {
		var name: String?
	
	    required init?(json: JSON) {
	        self.name = json["name"].string
	    }
	}

#### Code to call a service

	let github = GithubClient()
	let repos = github.repositories(owner: "cpageler93")
