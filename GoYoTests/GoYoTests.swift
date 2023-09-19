//
//  GoYoTests.swift
//  GoYoTests
//
//  Created by 方品中 on 2023/6/27.
//

import XCTest
@testable import GoYo

final class GoYoTests: XCTestCase {    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testSetRadius() {
        let view = UIView()
        view.frame.size = CGSize(width: 100, height: 50)
        view.doSetRadius()
        
        XCTAssertEqual(view.layer.cornerRadius, 25)
    }
    
    func testDate2String() {
        let date = Date(timeIntervalSince1970: 1687846472.07957)

        XCTAssertEqual("2023/06/27", date.date2String(dateFormat: "yyyy/MM/dd"))
        XCTAssertEqual("2023/06/27 14:14", date.date2String(dateFormat: "yyyy/MM/dd HH:mm"))
        XCTAssertEqual("2023/06/27 14:32", date.date2String(dateFormat: "yyyy/MM/dd mm:ss"))
        XCTAssertEqual("GMT+8", date.date2String(dateFormat: "zzz"))
        XCTAssertEqual("星期二", date.date2String(dateFormat: "EEEE"))
    }
}
