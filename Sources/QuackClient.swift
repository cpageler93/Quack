import Foundation
import Alamofire
import SwiftyJSON

public class QuackClient {

	let url: URL

	public init(url: URL) {
		self.url = url
	}

	public init?(urlString: String) {
		if let url = URL(string: urlString) {
			self.url = url
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
                                 params: [String: Any] = [:]) -> JSON? {
        
        let url = self.url.appendingPathComponent(path)
        let response = Alamofire.request(url,
                                         method: method,
                                         parameters: params).responseData()
        if let jsonData = response.result.value {
            return JSON(data: jsonData)
        }
        return nil
    }

}
