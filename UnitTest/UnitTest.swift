//
//  UnitTest.swift
//  UnitTest
//
//  Created by nsfish on 2020/5/31.
//  Copyright © 2020 nsfish. All rights reserved.
//

import XCTest
import Nimble

class UnitTest: XCTestCase {
    
    func testConan() throws {
        let directoryPath = "/Users/nsfish/Documents/Github/BangumiRenamer/TestCase/Bangumi/conan"
        let directoryURL = URL.init(fileURLWithPath: directoryPath)
        let sourceFileURL = directoryURL.appendingPathComponent("source.txt")
        let patternFileURL = directoryURL.deletingLastPathComponent()
                                         .deletingLastPathComponent()
                                         .appendingPathComponent("pattern.txt")
        let newFileNames = NSFBangumiRenamer.renameFiles(in: directoryURL,
                                                         withSource: sourceFileURL,
                                                         pattern: patternFileURL,
                                                         dryrun: true).sorted()
        
        expect(newFileNames[0]).to(equal("001 云霄飞车杀人事件 B:S"))
        expect(newFileNames[1]).to(equal("011（11~12） 钢琴奏鸣曲《月光》杀人事件★"))
        expect(newFileNames[2]).to(equal("012（13） 步美被绑架事件"))
        expect(newFileNames[3]).to(equal("287（309） 工藤新一纽约事件（推理篇） B:S"))
        expect(newFileNames[4]).to(equal("288（310） 工藤新一纽约事件（解决篇） B:F:S"))
    }
    
    func testOnePunchMan() throws {
        let directoryPath = "/Users/nsfish/Documents/Github/BangumiRenamer/TestCase/Bangumi/onepunman"
        let directoryURL = URL.init(fileURLWithPath: directoryPath)
        let sourceFileURL = directoryURL.appendingPathComponent("source.txt")
        let patternFileURL = directoryURL.deletingLastPathComponent()
                                         .deletingLastPathComponent()
                                         .appendingPathComponent("pattern.txt")
        let newFileNames = NSFBangumiRenamer.renameFiles(in: directoryURL,
                                                         withSource: sourceFileURL,
                                                         pattern: patternFileURL,
                                                         dryrun: true).sorted()
        let fileNamesInSourceFile = try String.init(contentsOf: sourceFileURL).components(separatedBy: "\n").sorted()
        
        expect(newFileNames).to(equal(fileNamesInSourceFile))
    }
}
