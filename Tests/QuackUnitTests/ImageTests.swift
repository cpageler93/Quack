//
//  ImageTests.swift
//  QuackLinuxUnitTests
//
//  Created by Christoph Pageler on 04.04.18.
//

#if !os(Linux)

import XCTest
#if os(macOS)
import AppKit
#else
import UIKit
typealias NSImage = UIImage
#endif

@testable import Quack


class PlaceholderService: Quack.Client {
    
    init() {
        super.init(url: URL(string: "http://via.placeholder.com")!)
    }
    
    public func imageWithSize(size: CGSize) -> Quack.Result<PlaceholderImage> {
        
        return respond(path: "/\(Int(size.width))x\(Int(size.height))", model: PlaceholderImage.self)
    }
    
}


class PlaceholderImage: Quack.DataModel {
    
    let image: NSImage?
    
    required init?(data: Data) {
        self.image = NSImage(data: data)
    }
    

}


class ImageTests: XCTestCase {
    
    
    func testImageWithSizeShouldReturnImage() {
        let service = PlaceholderService()
        let result = service.imageWithSize(size: CGSize(width: 200, height: 200))
        switch result {
        case .success(let image):
            XCTAssertNotNil(image.image)
        case .failure:
            XCTFail()
        }
    }
    
    
    
}


#endif
