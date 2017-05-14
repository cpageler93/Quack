import XCTest
import Foundation
@testable import Quack

class GithubQuackTests: XCTestCase {
    
    func testGithub() {
    	let github = GithubClient()
        XCTAssertEqual(github.url.absoluteString, "https://api.github.com")
    }

    func testGithubRepository() {
    	let github = GithubClient()
        let repos = github.repositories(owner: "cpageler93")
    	XCTAssertGreaterThan(repos?.count ?? 0, 0)
    }
    
    func testGithubRepositoryBranches() {
        let github = GithubClient()
        let repo = GithubRepository("cpageler93/Quack")
        let branches = github.repositoryBranches(repository: repo)
        XCTAssertGreaterThan(branches?.count ?? 0, 0)
    }

    func testDummyAccountServiceWithValidURL() {
    	let service = DummyAccountServiceClient(urlString: "https://hellothisisurl.com")
    	XCTAssertEqual(service?.url.absoluteString, "https://hellothisisurl.com")
    }

    func testDummyAccountServiceWithInvalidURL() {
    	let service = DummyAccountServiceClient(urlString: "")
    	XCTAssertNil(service)
    }
}
