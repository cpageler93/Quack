import Foundation
import Alamofire
import SwiftyJSON

public class QuackClient {

	let url: URL
    let manager: Alamofire.SessionManager
    
    public init(url: URL,
                timeoutInterval: TimeInterval = 5,
                serverTrustPolicies: [String: ServerTrustPolicy] = [:]) {
		self.url = url
        
        // Setup Alamofire
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForResource = timeoutInterval
        configuration.httpAdditionalHeaders = Alamofire.SessionManager.defaultHTTPHeaders
        
        self.manager = Alamofire.SessionManager(configuration: configuration,
                                                serverTrustPolicyManager: ServerTrustPolicyManager(policies: serverTrustPolicies))
	}

	convenience public init?(urlString: String,
	                         timeoutInterval: TimeInterval = 5,
	                         serverTrustPolicies: [String: ServerTrustPolicy] = [:]) {
		if let url = URL(string: urlString) {
            self.init(url: url,
                      timeoutInterval: timeoutInterval,
                      serverTrustPolicies: serverTrustPolicies)
		} else {
			return nil
		}
	}
    
    public func respond<Model: QuackModel>(method: HTTPMethod = .get,
                                           path: String,
                                           params: [String: Any] = [:],
                                           model: Model.Type) -> Model? {
        if let json = respondWithJSON(method: method, path: path, params: params) {
            return Model(json: json)
        }
        return nil
    }

    public func respondWithArray<Model: QuackModel>(method: HTTPMethod = .get,
                                                    path: String,
                                                    params: [String: Any] = [:],
                                                    model: Model.Type) -> [Model]? {
        if let json = respondWithJSON(method: method, path: path, params: params) {
            if let jsonArray = json.array {
                var models: [Model] = []
                for jsonObject in jsonArray {
                    if let model = Model(json: jsonObject) {
                        models.append(model)
                    }
                }
                return models
            }
        }
        
        return nil
	}
    
    private func respondWithJSON(method: HTTPMethod = .get,
                                 path: String,
                                 params: [String: Any] = [:],
                                 headers: [String: String] = [:]) -> JSON? {
        
        let url = self.url.appendingPathComponent(path)
        let response = Alamofire.request(url,
                                         method: method,
                                         parameters: params,
                                         headers: headers
                                         ).responseData()
        if let jsonData = response.result.value {
            return JSON(data: jsonData)
        }
        return nil
    }

}
