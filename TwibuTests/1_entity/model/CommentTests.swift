//
//  CommentTests.swift
//  TwibuTests
//
//  Created by abeyuya on 2019/06/26.
//  Copyright © 2019 abeyuya. All rights reserved.
//

import XCTest
@testable import Twibu

class CommentTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTitleReplacedText1() {
        let text = "NHK「ノーナレ」報道についてのご報告 | 今治タオル公式総合案... > 感想コメント"
        let title = "NHK「ノーナレ」報道についてのご報告 | 今治タオル公式総合案..."
        let result = Comment.titleReplacedText(text: text, title: title)
        assert(result == "{title} > 感想コメント")
    }

   func testTitleReplacedText2() {
        let text = "2人は約2年にわたって極秘交際を続けていたことが関係者への取材でわかった――。\n\n《祝・電撃婚》人気声優・梶裕貴と竹達彩奈が「深夜密会の2年」を関係者にも極秘にしてきた理由\n\n#梶裕貴 #竹達彩奈 #スクープ速報 #週刊文春 {url}"
        let title = "《祝・電撃婚》人気声優・梶裕貴と竹達彩奈が「深夜密会の2年」を関係者にも極秘にしてきた理由"
        let result = Comment.titleReplacedText(text: text, title: title)
        print(result)
        assert(result == "2人は約2年にわたって極秘交際を続けていたことが関係者への取材でわかった――。\n\n{title}\n\n#梶裕貴 #竹達彩奈 #スクープ速報 #週刊文春 {url}")
    }

    // 微妙にタイトルが変更されているので仕方なし
    func testTitleReplacedText3() {
        let text = "⚽️🏃‍♂️🏋️‍♀️🏓🎾\n\nGoogle Japan Blog: Google が 2020 年東京オリンピック・パラリンピックのオフィシャルサポーターに {url}o/M6t7UZSEKF"
        let title = "\nGoogle Japan Blog: Google が 東京2020オリンピック・パラリンピック競技大会のオフィシャルサポーターに\n"
        let result = Comment.titleReplacedText(text: text, title: title)
        print(result)
        assert(result == "⚽️🏃‍♂️🏋️‍♀️🏓🎾\n\nGoogle Japan Blog: Google が 2020 年東京オリンピック・パラリンピックのオフィシャルサポーターに {url}o/M6t7UZSEKF")
    }



    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}

