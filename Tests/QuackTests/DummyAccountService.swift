import Foundation
@testable import Quack

class DummyAccountServiceClient: QuackClient {
    
    func getVoid() -> QuackResult<Void> {
        return respondVoid(path: "foo/bar")
    }
    
    func getVoid(completion: @escaping (QuackVoid) -> (Void)) {
        respondVoidAsyny(path: "foo/bar", completion: completion)
    }
    
}
