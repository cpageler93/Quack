import Foundation
import SwiftyJSON

public protocol QuackModel {
    init?(json: JSON)
}
