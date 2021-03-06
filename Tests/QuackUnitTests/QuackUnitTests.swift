//
//  QuackUnitTests.swift
//  QuackUnitTests
//
//  Created by Christoph Pageler on 18.12.17.
//

import XCTest
@testable import Quack

public class QuackUnitTests: XCTestCase {

    public static var allTests = [
        ("testGithub", testGithub),
        ("testGithubRepository", testGithubRepository),
        ("testGithubRepositoryAsync", testGithubRepositoryAsync),
        ("testGithubRepositoryBranches", testGithubRepositoryBranches),
        ("testDummyAccountServiceWithValidURL", testDummyAccountServiceWithValidURL),
        ("testDummyAccountServiceWithInvalidURL", testDummyAccountServiceWithInvalidURL)
    ]

    func testGithub() {
        let github = GithubClient()
        XCTAssertEqual(github.url.absoluteString, "https://api.github.com")
    }
    
    func testGithubRepository() {
        let github = GithubClient()
        let repos = github.repositories(owner: "cpageler93")
        switch repos {
        case .success(let repos):
            XCTAssertGreaterThan(repos.count, 0)
        case .failure(let error):
            XCTAssertNil(error)
        }
    }
    
    func testGithubRepositoryAsync() {
        let github = GithubClient()
        let repositoryExpectation = self.expectation(description: "Github Repositories")
        github.repositories(owner: "cpageler93") { repos in
            switch repos {
            case .success(let repos):
                XCTAssertGreaterThan(repos.count, 0)
            case .failure(let error):
                XCTAssertNil(error)
            }
            repositoryExpectation.fulfill()
        }
        
        self.waitForExpectations(timeout: 15, handler: nil)
    }
    
    func testGithubRepositoryBranches() {
        let github = GithubClient()
        let repo = GithubRepository("cpageler93/Quack")
        let branches = github.repositoryBranches(repository: repo)
        switch branches {
        case .success(let branches):
            XCTAssertGreaterThan(branches.count, 0)
        case .failure(let error):
            XCTAssertNil(error)
        }
    }

    func testDummyAccountServiceWithValidURL() {
        let service = DummyAccountServiceClient(urlString: "https://hellothisisurl.com")
        XCTAssertEqual(service?.url.absoluteString, "https://hellothisisurl.com")
    }
    
    func testDummyAccountServiceWithInvalidURL() {
        let service = DummyAccountServiceClient(urlString: "")
        XCTAssertNil(service)
    }
    
    func testConsulAgentReload() {
        let consul = Consul()
        let result = consul.agentReload()
        switch result {
        case .success():
            print("success")
        case .failure(let error):
            XCTAssertNil(error)
        }
    }
    
    func testConsulAgentChecks() {
        let consul = Consul()
        let checks = consul.agentChecks()
        switch checks {
        case .success(let checks):
            XCTAssertGreaterThanOrEqual(checks.count, 0)
        case .failure(let error):
            XCTAssertNil(error)
        }
    }
    
    func testConsulKeyValue() {
        let consul = Consul()
        let write = consul.writeKey("QuackKey", value: "QuackValue")
        switch write {
        case .success(let write):
            XCTAssertTrue(write)
        case .failure(let error):
            XCTAssertNil(error)
        }
        
        let key = consul.readKey("QuackKey")
        switch key {
        case .success(let key):
            XCTAssertEqual(key.decodedValue(), "QuackValue")
        case .failure(let error):
            XCTAssertNil(error)
        }
    }
    
    func testConsulReadInvalidKey() {
        let consul = Consul()
        let key = consul.readKey("FooBar")
        switch key {
        case .success:
            XCTFail("Should fail because FooBar is an invalid key")
        case .failure(let error):
            switch error.type {
            case .invalidStatusCode(let code):
                XCTAssertEqual(code, 404)
            default:
                XCTFail("Should fail with invalidStatusCode Error")
            }
        }
    }
    
}
