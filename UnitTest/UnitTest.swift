//
//  UnitTest.swift
//  UnitTest
//
//  Created by nsfish on 2020/5/31.
//  Copyright © 2020 nsfish. All rights reserved.
//

import XCTest

class UnitTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        let directoryPath = "/Users/nsfish/Documents/Github/BangumiRenamer/TestCase/Bangumi/conan"
        let directoryURL = URL.init(fileURLWithPath: directoryPath)
        let sourceFileURL = directoryURL.appendingPathComponent("source.txt")
//        NSFBangumiRenamer.renameFiles(in: directoryURL, withSource: sourceFileURL, pattern: <#T##URL#>)
    }
}
