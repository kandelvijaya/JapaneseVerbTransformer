//
//  JapaneseLibraryTester.swift
//  JapaneseLibraryTester
//
//  Created by Vijaya Prakash Kandel on 6/30/15.
//  Copyright © 2015 Vijaya Prakash Kandel. All rights reserved.
//


import XCTest


class JapaneseTransformerCore: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
    func testConvertingJapaneseToRomaji(){
        //MARK:- standalone kanjia are hard to translate
        //One kanji can be differently romanijed its a pain now
        let sampleWords = ["書きます","私は","休み","勉強します","こにちは"]
        let needsToBeRomaji = ["kakimasu", "watashiha", "yasumi", "benkyoushimasu", "konichiha"]
        
        //test
        for index in 0..<sampleWords.count{
            let nihongo = sampleWords[index]
            let romaji = needsToBeRomaji[index]
            let translated = JapaneseVerbTransformer().convertAnyJapaneseToRomaji(sampleWords[index])
            XCTAssertEqual(translated, needsToBeRomaji[index], "Conversion Failed at \(sampleWords[index])")
        }
    }
    
    func testThatJapaneseWordsConvertToCorrectGroups(){
        let sampleGroup1Verbs = ["書きます","言います","読む","ある　"]
        let sampleGroup2Verbs = ["あげる","できる","見る","います","食べる","たべます"]
        let sampleGroup3Verbs = ["来る","くる","する"]
        let exceptionGroup2 = ["入る","帰る","知る"]
        
        let notVerbs = ["雨","電車","車です","ビジェ","心配しないでください"]
        let oneCharParticles = ["へ","を","は"]
        let romajis = ["hello","konichiwa","kerei","tereve", "kakimasu"]
        
        
        //1.group1 test
        for index in sampleGroup1Verbs{
            if let group = JapaneseVerbTransformer().determineGroupOfVerb(index){
                let isGroupOne = ( group == JPVerbGroup.one ) ? true : false
                
                XCTAssert(isGroupOne, "Group 1 Conversion incorrect")
            }else{
                XCTFail()
            }
        }
        
        //Group2 test
        //1.group1 test
        for index in sampleGroup2Verbs{
            println(index)
            if let group = JapaneseVerbTransformer().determineGroupOfVerb(index){
                let isGroupTwo = ( group == JPVerbGroup.two ) ? true : false
                println("\(index) is GROUP \(group.rawValue)")
                XCTAssert(isGroupTwo, "Group 2 Conversion incorrect \(index)")
            }else{
                XCTFail()
            }
            


        }
        
        //Group 3 Test
        //1.group1 test
        for index in sampleGroup3Verbs{
            if let group = JapaneseVerbTransformer().determineGroupOfVerb(index){
                let isGroupThree = ( group == JPVerbGroup.three ) ? true : false
                
                XCTAssert(isGroupThree, "Group 3 Conversion incorrect")
            }else{
                XCTFail()
            }
        }
        
        //Check for verbs with -iru -eru ending that fall on group 1 
        //1.group1 test
        for index in exceptionGroup2{
            if let group = JapaneseVerbTransformer().determineGroupOfVerb(index){
                let isGroupOne = ( group == JPVerbGroup.one ) ? true : false
                
                XCTAssert(isGroupOne, "Group 2 exception Conversion incorrect")
            }else{
                XCTFail()
            }
            
            
            
        }
        
        //Check for non-verbs 
        for index in notVerbs{
            if let _ = JapaneseVerbTransformer().determineGroupOfVerb(index){
                XCTFail()
            }
        }
        
        //Check for oneCharacter
        for index in oneCharParticles{
            if let _ = JapaneseVerbTransformer().determineGroupOfVerb(index){
                XCTFail()
            }
        }
        
        //Check for romaji
        for indexRomaji in romajis{
            if let _ = JapaneseVerbTransformer().determineGroupOfVerb(indexRomaji){
                XCTFail()
            }
        }
    }
    
    
    
    func testThatRootVerbConvertsToStem(){
        //+
        let rootVerbs = ["ある","おもう","いる","食べる","来る"]
        let rootVerbsStemExpected = ["ar", "omo", "i", "tabe", "ki"]
        //-
        let notVerbs = ["雨","便利","食べ物","🍏"]
        //Boundary
        let exceptionsRoot = ["入る","帰る","会う","まつ"]
        let exceptionRootStem = ["hair", "kaer", "a", "mach"]
        
        
        //test positive
        for index in 0..<rootVerbs.count{
            
            let converted = JapaneseVerbTransformer().convertToStemWord(rootVerbs[index])
            let expected = rootVerbsStemExpected[index]
            
            if converted != nil{
                XCTAssertEqual(converted!, expected, "Stem Conversion Bad")
            }else{
                XCTFail("Conversion Failed")
            }
        }
        
        //test Not Verbs
        for index in notVerbs{
            if let converted = JapaneseVerbTransformer().convertToStemWord(index){
                XCTFail("Converted something that shouldnt be converted. Its not a verb at all")
            }
        }
        
        //test for exceptions
        for index in 0..<exceptionsRoot.count{
            let converted = JapaneseVerbTransformer().convertToStemWord(exceptionsRoot[index])
            let expected = exceptionRootStem[index]
            
            if converted != nil{
                XCTAssertEqual(converted!, expected, "Excpetion Stem Conversion Bad")
            }else{
                XCTFail("Got nil!.Failed.")
            }
        }
        
    }
    
    
    
    
    func testThatMasuVerbConvertsToStem(){
        //+
        let masuVerbs = ["書きます","思います","います","たべます","来ます"]
        let masuVerbsStemExpected = ["kak", "omo", "i", "tabe", "ki"]
        //-u
        let notVerbs = ["雨","便利","食べ物","🍏"]
        //Boundary
        let exceptionsMasu = ["入ります","帰ります","会います","まちます", "勉強します"]
        let exceptionMasuStem = ["hair", "kaer", "a", "mach", "benkyoushi"]
        
        
        //test positive
        for index in 0..<masuVerbs.count{
            
            let converted = JapaneseVerbTransformer().convertToStemWord(masuVerbs[index])
            let expected = masuVerbsStemExpected[index]
            
            if converted != nil{
                XCTAssertEqual(converted!, expected, "Stem Conversion Bad")
            }else{
                XCTFail("Conversion Failed")
            }
        }
        
        //test Not Verbs
        for index in notVerbs{
            if let converted = JapaneseVerbTransformer().convertToStemWord(index){
                XCTFail("Converted something that shouldnt be converted. Its not a verb at all")
            }
        }
        
        //test for exceptions
        for index in 0..<exceptionsMasu.count{
            let converted = JapaneseVerbTransformer().convertToStemWord(exceptionsMasu[index])
            let expected = exceptionMasuStem[index]
            
            if converted != nil{
                XCTAssertEqual(converted!, expected, "Excpetion Stem Conversion Bad")
            }else{
                XCTFail("Got nil!.Failed.")
            }
        }

    }
    
    
    //Test Root Form Conversion
    func testThatVerbsConvertToRootForm(){
        //+
        let masuVerbs = ["書きます","思います","います","たべます","来ます"]
        let masuVerbsRootExpected = ["kaku", "omou", "iru", "taberu", "kuru"]
        let masuVerbsRootKanjiExpected = ["書く","思う","いる","たべる","来る"]
        //-u
        let notVerbs = ["雨","便利","食べ物","🍏"]
        //Boundary
        let exceptionsMasu = ["入ります","帰ります","会います","まちます", "勉強します"]
        let exceptionMasuRoot = ["hairu", "kaeru", "au", "matsu", "benkyoushuru"]
        
        
        //test positive
        for index in 0..<masuVerbs.count{
            
            let converted = JapaneseVerbTransformer().convertToRootForm(masuVerbs[index])
            let expected = masuVerbsRootExpected[index]
            let expectedKanjiRoot = masuVerbsRootKanjiExpected[index]
            
            if converted != nil{
                XCTAssertEqual(converted!.romaji, expected, "Root Conversion Bad")
                XCTAssertEqual(converted!.japanese!, expectedKanjiRoot, "Root Conversion Bad")
            }else{
                XCTFail("Conversion Failed")
            }
        }
        
        //test Not Verbs
        for index in notVerbs{
            if let converted = JapaneseVerbTransformer().convertToRootForm(index){
                XCTFail("Converted something that shouldnt be converted. Its not a verb at all")
            }
        }
        
        //test for exceptions
        for index in 0..<exceptionsMasu.count{
            let converted = JapaneseVerbTransformer().convertToRootForm(exceptionsMasu[index])
            let expected = exceptionMasuRoot[index]
            
            if converted != nil{
                XCTAssertEqual(converted!.romaji, expected, "Excpetion Root Conversion Bad")
            }else{
                XCTFail("Got nil!.Failed.")
            }
        }
    }
    
    //Test Te Form Conversion
    func testThatVerbsConvertToTeForm(){
        //+
        let masuVerbs = ["書きます","思います","います","たべます","来ます"]
        let masuVerbsTeFormExpected = ["kaite", "omotte", "ite", "tabete", "kite"]
        //-u
        let notVerbs = ["雨","便利","食べ物","🍏", "雨です", "寒い"]
        //Boundary
        let exceptionsMasu = ["入ります","帰ります","会います","まちます", "勉強します"]
        let exceptionMasuTe = ["haitte", "kaette", "atte", "matte", "benkyoushite"]
        
        
        //test positive
        for index in 0..<masuVerbs.count{
            
            let converted = JapaneseVerbTransformer().convertToTeForm(masuVerbs[index])
            let expected = masuVerbsTeFormExpected[index]
            
            if converted != nil{
                XCTAssertEqual(converted!, expected, "Root Conversion Bad")
            }else{
                XCTFail("Conversion Failed")
            }
        }
        
        //test Not Verbs
        for index in notVerbs{
            if let converted = JapaneseVerbTransformer().convertToTeForm(index){
                XCTFail("Converted something that shouldnt be converted. Its not a verb at all")
            }
        }
        
        //test for exceptions
        for index in 0..<exceptionsMasu.count{
            let converted = JapaneseVerbTransformer().convertToTeForm(exceptionsMasu[index])
            let expected = exceptionMasuTe[index]
            
            if converted != nil{
                XCTAssertEqual(converted!, expected, "Excpetion Root Conversion Bad")
            }else{
                XCTFail("Got nil!.Failed.")
            }
        }
    }

    //Test Te Form Conversion
    func testThatVerbsConvertToTaForm(){
        //This is a simple task as te form's last char "e" is swapped with "a"
        //So simple test but the correctness of this test depends on the correctness of Te Conversion
        let sampleVerbs = ["書きます","まちます","あそびます","読む","散歩します","します","見ます","来ます"]
        let expectations = ["kaita","matta","asonda","yonda","sanposhita","shita","mita","kita"]
        let notVerbs = ["雨です","amedesu","ロヴェ","スマホ"]
        
        //tests
        for index in 0..<sampleVerbs.count{
            let converted = JapaneseVerbTransformer().convertToTAFrom(sampleVerbs[index])
            let expected = expectations[index]
            
            if converted != nil{
                XCTAssertEqual(converted!, expected, "Bad Conversion")
            }else{
                XCTFail("Failed!")
            }
        }
        
        //tests for not verbs at all
        for index in notVerbs{
            if let converted = JapaneseVerbTransformer().convertToTAFrom(index){
                XCTFail("Converted something that is not possible to convert.")
            }
        }
        
    }
    
    
    func testBasicJPVerbsConjugationWithTense(){
        //Try to check for exception case, both negative and continious in each tense
        //Check past
        if let result = JapaneseVerbTransformer().conjugateJapaneseVerbToBasicForm("来ます", tense:TenseType.Past , negative: false, continious: false){
            XCTAssertEqual("kimashita", result, "Bad Conjugation")
        }else{
            XCTFail("Couldnt conjugate")
        }
        
        if let result = JapaneseVerbTransformer().conjugateJapaneseVerbToBasicForm("書きます", tense: TenseType.Past, negative: true, continious: true){
            XCTAssertEqual("kaiteimasendeshita", result, "Bad Conjugation")
        }else{
            XCTFail("Couldnt conjugate")
        }

        
        //Check future:Present
        
        if let result = JapaneseVerbTransformer().conjugateJapaneseVerbToBasicForm("行きます", tense: TenseType.Future, negative: true, continious: true){
            XCTAssertEqual("itteimasen", result, "Bad Conjugation")
        }else{
            XCTFail("Couldnt conjugate")
        }
        
        if let result = JapaneseVerbTransformer().conjugateJapaneseVerbToBasicForm("思います", tense: TenseType.Present, negative: false, continious: true){
            XCTAssertEqual("omotteimasu", result, "Bad Conjugation")
        }else{
            XCTFail("Couldnt conjugate")
        }
        

        //Check for exceptions
        if let result = JapaneseVerbTransformer().conjugateJapaneseVerbToBasicForm("会います", tense: TenseType.Present, negative: false, continious: true){
            XCTAssertEqual("atteimasu", result, "Bad Conjugation")
        }else{
            XCTFail("Couldnt conjugate")
        }
        
        
        //Check for not possible forms
        let notVerbs = ["雨","便利","食べ物","🍏", "雨です", "寒い"]
        for index in notVerbs{
            if let _ = JapaneseVerbTransformer().conjugateJapaneseVerbToBasicForm(index, tense: TenseType.Present, negative: false, continious: true){
                XCTFail("Conjugated something that cant be.")
            }
        }
        
    }
    
    
    //Testing masu verb decomposition
    func testThatMasuVerbIsDecomposedCorrectly(){
        let masuVerbs = ["行きます","行きません","行きませんでした","行きました","行っています", "勉強していませんでした"]
        let ikimasuParts = VerbPartsSimple(tense: .Present, negative: false, continious: false, possibleRoot: "行く")
        let ikimasenPArts = VerbPartsSimple(tense: .Present, negative: true, continious: false, possibleRoot: "行く")
        let ikimasendeshitaParts = VerbPartsSimple(tense: .Past, negative: true, continious: false, possibleRoot: "行く")
        let ikimashitaParts = VerbPartsSimple(tense: .Past, negative: false, continious: false, possibleRoot: "行く")
        let itteimasuParts = VerbPartsSimple(tense: .Present, negative: false, continious: true, possibleRoot: "行")
        let benkyoushiteimasendesita = VerbPartsSimple(tense: .Past, negative: true, continious: true, possibleRoot: "勉強し")
        
        let masuPartsExpected = [ikimasuParts, ikimasenPArts, ikimasendeshitaParts, ikimashitaParts, itteimasuParts, benkyoushiteimasendesita]
        
        
        //TODO:- can be added lots of test but i think it depends
        
        for index in 0..<masuVerbs.count{
            let expectedParts = masuPartsExpected[index]
            if let parts = JapaneseVerbTransformer().decomposeJPVerbToSimpleParts(masuVerbs[index]){
                
                XCTAssertEqual(parts.tense!, expectedParts.tense!, "Parts Tense Dont Match ")
                XCTAssertEqual(parts.negative, expectedParts.negative, "Parts negative intent Dont Match ")
                XCTAssertEqual(parts.continious, expectedParts.continious, "Parts continious intent Dont Match ")
                XCTAssertEqual(parts.possibleRoot!, expectedParts.possibleRoot!, "Parts Possible Roots Dont Match ")
                
            }else{
                XCTFail("Bad!")
            }
            
        }
        
    }
    
    
    
    
}
