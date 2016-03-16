//
//  JapaneseVerbTransformer.swift
//
//  Created by Vijaya Prakash Kandel on 6/29/15.
//  Copyright © 2015 Vijaya Prakash Kandel. All rights reserved.
//

import Foundation

enum JPVerbGroup:Int{
    case one = 1
    case two
    case three
}

struct IntermediateVerbTransformationState{
    var romaji:String
    var kaniPart:String
}

enum TenseType{
    case Present, Past, Future
}

struct VerbPartsSimple{
    var tense:TenseType?
    var negative = false
    var continious = false
    var possibleRoot:String?
}

class JapaneseVerbTransformer:NSObject{
    
    //Properties
    //FIXME:-look all masu forms
    let masuEndidngs = ["ます","ません","ました","ませんでした"]
    let desuEndings = ["desu","deshita"]
    var masuEndingsRomaji = [String]()
    
    override init() {
        super.init()
        configureFirst()
    }
    
    func configureFirst(){
        for index in masuEndidngs{
            masuEndingsRomaji.append(self.convertAnyJapaneseToRomaji(index))
        }
    }
    
    //MARK:- determine group
    
    //1.
    /**
    Determine the group of the given root word or masu form. ** doesnot accept teimasu forms
    
    
    :param: verb String **Can be in both JAPANESE ONLY for the technical reasons. It doensot work with katakana too. Never meant to be that way.
    
    :returns: JPVerbGroup enum
    */
    func determineGroupOfVerb(var verb:String) ->JPVerbGroup?{
        if let goodVerb = getTrimmedVerbByCheckingForVerbValidity(verb){
            verb = goodVerb
        }else{
            return nil
        }
        
        //the verb might be in hirgagana, katakana , kanji or romaji
        //if its romaji then get to hiragana and proceed
        
        //Check to sepeater masu or root or invalid one
        if !isVerbInMasuForm(verb) && isVerbInRootForm(verb){
            return determineGroupOfRootVerb(verb)
        }else if isVerbInMasuForm(verb){
            return determineGroupOfMasuVerb(verb)
        }
        
        return nil
    }
    
    private func determineGroupOfRootVerb(verb:String)->JPVerbGroup{
        let romajiVerb = convertAnyJapaneseToRomaji(verb).lowercaseString
        
        //FIXME:- make a complete list of exception
        let exceptionToGroup2or1 = ["hairu", "kaeru", "shiru"]
        
        if (romajiVerb == "kuru" || romajiVerb == "suru") {     //FIXME:-fix me if im wrong
            if (verb.rangeOfCharacterFromSet(NSCharacterSet(charactersInString: "来"), options: nil, range: nil) != nil) {
                return JPVerbGroup.three
            }
            //FIXME:- fixme
            return JPVerbGroup.three
        }
        
        
        //PROCCED by checking the last three letter or 2 letters
        if count(romajiVerb) < 3{
            //if its u maybe thats not possible
            //its not 3rd group
            //its not 2nd group becuase if it was then we would get no stem word
            //so its Group 1 like au-> meet
            return JPVerbGroup.one
        }
        
        let last3Char = romajiVerb.substringFromIndex(advance(romajiVerb.endIndex, -3))
        
        if last3Char != "iru" && last3Char != "eru"{
            return JPVerbGroup.one
        }else{
            //if it is eru/iru
            //check the exception
            if (exceptionToGroup2or1 as NSArray).containsObject(romajiVerb) {
                return JPVerbGroup.one
            }else{
                //isnot kuru suru
                //is not in the exception
                return JPVerbGroup.two
            }
        }
    }
    
    //expects the translation both in HIRAGANA OR KANJI
    private func determineGroupOfMasuVerb(var verb:String)->JPVerbGroup?{
        for index in masuEndidngs{
            
            if verb.rangeOfString(index, options: NSStringCompareOptions.BackwardsSearch, range: nil, locale: nil) == nil {
                continue
            }
            
            //else
            //trim the masu
            verb = verb.componentsSeparatedByString(index).first!
            
            //if the verb contains
            if verb.containsChar("来") {//|| verb.contains("する"){
                return JPVerbGroup.three
            }
            
            //if the last char is "し"
            if verb.substringFromIndex(advance(verb.endIndex, -1)) == "し"{
                return JPVerbGroup.three
            }
            
            let romajiVerb = convertAnyJapaneseToRomaji(verb).lowercaseString
            //FIXME:-Research
            //if the masu verb is in te or ta form its not possible to reverse engineer the root and group
            
            let continiousSuffixs = ["ta","da","te","nde", "tei", "ndei"]
            
            for index in continiousSuffixs{
                if romajiVerb.hasSuffix(index){
                    return nil
                }
            }
            
            //if last char is "i" -> 1
            //else if "e" -> 2
            let last1CharRomaji = romajiVerb.substringFromIndex(advance(romajiVerb.endIndex, -1))
            //FIXME:-add exception here
            //if the word is imasu then the last i is the same as the
            if romajiVerb == last1CharRomaji && last1CharRomaji == "i"{
                //it might be imasu which is in group 2
                return JPVerbGroup.two
            }
            
            if last1CharRomaji == "i" && (romajiVerb != "mi" && verb != "i" && verb != "deki" ){
                return JPVerbGroup.one
            }else{
                return JPVerbGroup.two
            }
            
            if last1CharRomaji == "e"{
                return JPVerbGroup.two
            }
        }
        
        return nil
    }
    
    //2. Determine the stem of the given root word or masu word with or without the group
    //convert to the stem word from either masu form or root form
    func convertToStemWord(var verb:String) -> String?{
        
        //        guard let goodVerb = getTrimmedVerbByCheckingForVerbValidity(verb) else{
        //            return nil
        //        }
        if let goodVerb = getTrimmedVerbByCheckingForVerbValidity(verb){
            verb = goodVerb
        }else{
            return nil
        }
        
        //Check to sepeater masu or root or invalid one
        if !isVerbInMasuForm(verb) && isVerbInRootForm(verb){
            return convertToStemFromRootForm(verb)
        }else if isVerbInMasuForm(verb){
            return convertToStemFromMasuFrom(verb)
        }
        
        return nil
    }
    
    //MARK:- Convert To Stem Word
    //expects the provided char in hiragana or kanji. returns romaji and intermediate kanji
    private func convertToStemFromRootForm(rootVerb:String) -> String?{
        let group = determineGroupOfRootVerb(rootVerb)
        let romajiVerb = convertAnyJapaneseToRomaji(rootVerb)
        
        switch group{
        case .one:
            //u dropper
            //But if its su or tsu ending its replaced by sh and ch respectively
            let possibleStem = romajiVerb
            if possibleStem.hasSuffix("su"){
                if possibleStem.hasSuffix("tsu"){
                    return possibleStem.substringToIndex(advance(possibleStem.endIndex, -3)) + "ch"
                }else{
                    return possibleStem.substringToIndex(advance(possibleStem.endIndex, -2)) + "sh"
                }
            }else{
                //drop the U
                return possibleStem.substringToIndex(advance(possibleStem.endIndex, -1))
            }
        case .two:
            //ru dropper
            if romajiVerb.hasSuffix("ru"){
                return romajiVerb.substringToIndex(advance(romajiVerb.endIndex, -2))
            }else{
                return nil
            }
        case .three:
            //FIXME:-attention G3 stem
            //kuru -> ki
            //suru -> si
            if romajiVerb.hasSuffix("suru") || romajiVerb.hasSuffix("kuru"){
                return romajiVerb.substringToIndex(advance(romajiVerb.endIndex , -3)) + "i"
            }
            return nil
        }
    }
    
    //The input is supposed to be either hiragana or kanji
    private func convertToStemFromMasuFrom(masuVerb:String) -> String?{
        var group = JPVerbGroup.one
        if let g = determineGroupOfVerb(masuVerb){
            group = g
        }else{
            return nil
        }
        
        //this conversion will be based on romaji so we cant presever the kanji or the hiragana.
        var romajiMasuVerb = convertAnyJapaneseToRomaji(masuVerb).lowercaseString
        
        //trim the mas.... part
        for index in masuEndingsRomaji{
            if romajiMasuVerb.hasSuffix(index){
                romajiMasuVerb = romajiMasuVerb.stringByReplacingOccurrencesOfString(index, withString: "", options: NSStringCompareOptions.BackwardsSearch, range: nil)
                break //get out of the loop
            }
        }
        
        //if group is valid
        switch group{
        case .one:
            //remove i ending from the last part
            romajiMasuVerb = romajiMasuVerb.substringToIndex(advance(romajiMasuVerb.endIndex, -1))
        case .two:
            //remove ru
            fallthrough
        case .three:
            //remove ru
            fallthrough
        default:
            break;
        }
        
        return romajiMasuVerb
    }
    
    
    //MARK:-convert to root word (kanji)
    /**
    Convert a given verb to a root form
    
    :param: verb the verb must be in japanese script and either masu form or root form itself
    
    :returns: Tuple (romaji:String, japanese:String?)?
    */
    func convertToRootForm(verb:String)->(romaji:String,japanese:String?)?{
        var group = JPVerbGroup.one
        var stemWord = ""
        
        if let g = determineGroupOfVerb(verb){
            group = g
        }else{
            return nil
        }
        
        if let s = convertToStemWord(verb){
            stemWord = s
        }else{
            return nil
        }
        
        //Convert preserving the Kanji part
        var kanjiPart:String?
        var romajiRoot:String?
        
        switch group{
        case .one:
            //add u
            //if the stem word is of matsu -> mach dasu->dash
            if stemWord.hasSuffix("ch"){
                romajiRoot = stemWord.substringToIndex(advance(stemWord.endIndex, -2)) + "tsu"
            }else if stemWord.hasSuffix("sh"){
                romajiRoot = stemWord.substringToIndex(advance(stemWord.endIndex, -2)) + "su"
            }else{
                romajiRoot = stemWord + "u"
            }
        case .two:
            //add ru
            romajiRoot = stemWord + "ru"
        case .three:
            //FIXME:-know the 3rd group: suru, kuru :: si- > suru ki-> kuru
            romajiRoot = stemWord.substringToIndex(advance(stemWord.endIndex, -1)) + "uru"
        }
        
        
        //Inner function
        var japaneseRoot:String?
        if isVerbInMasuForm(verb){
            var originalVerb = verb
            let hiraganaVerb = convertKanjiToHiragana(verb)
            let hiraganaOfRoot = convertRomajiToHiragana(romajiRoot!)
            var masuStrippedHiragana = ""
            
            
            //*****
            //originalVerb              :入ります           :Find whats different in this and below
            //hiraganaOfOrigainalVerb   :はいります
            //hiraganaOfRootVerb        :はいる             :find whats differnt in this from above
            //                                             :Add them together -> kanji root
            //
            //          if originalVerb == hiraganaOfRoot then trim the masu off the originalVerb and one more letter 
            //          add the last char to the above
            //*****
            
            //from the original verb throw whats different in it and the hiragana version
            for index in 0..<count(originalVerb){
                let partOfOriginalVerb = originalVerb.substringFromIndex(advance(originalVerb.startIndex, index))
                if hiraganaVerb.hasSuffix(partOfOriginalVerb){
                    //some part of original verb matches the hiragana
                    //remove the matching from the original verb and break out
                    originalVerb = originalVerb.stringByReplacingOccurrencesOfString(partOfOriginalVerb, withString: "", options: nil, range: nil)
                    break;
                }
            }
            
            if count(originalVerb) == 0{
                originalVerb = verb
                for index in masuEndidngs{
                    if originalVerb.hasSuffix(index){
                        //change the originalVerb
                        originalVerb = originalVerb.stringByReplacingOccurrencesOfString(index, withString: "", options: nil, range: nil)
                        //remove the last character if its group 1 and if the char count is greater than 1
                        //this avoids imasu
                        if group == .one && count(originalVerb) > 1{
                            originalVerb = originalVerb.substringToIndex(advance(originalVerb.endIndex, -1))
                        }
                        break;
                    }
                }
            }
            
            //then add what is  different in romajiHirgana and the masu tripped original hiragana
            var someCharactersMatch = false
            for index in 0..<count(hiraganaOfRoot){
                let partOfRootHiragana = hiraganaOfRoot.substringToIndex(advance(hiraganaOfRoot.endIndex, -index))
                if hiraganaVerb.hasPrefix(partOfRootHiragana){
                    //remove the occurance of mathing string from the rootsHiragana
                    let missingEndToRoot = hiraganaOfRoot.stringByReplacingOccurrencesOfString(partOfRootHiragana, withString: "", options: nil, range: nil)
                    originalVerb += missingEndToRoot
                    someCharactersMatch = true
                    break;
                }
            }
            
            if !someCharactersMatch{
                //if the hiragana of the masu  and the root are different it is highly probable
                //it happens for simasu -> suru
                //kimasu -> kuru
                //swipe the firt character of the root with the original Verb
                originalVerb = originalVerb + hiraganaOfRoot.substringFromIndex(advance(hiraganaOfRoot.endIndex, -1))
            }

            japaneseRoot = originalVerb
        }
        
        return (romajiRoot!, japaneseRoot)
    }
    
    //MARK:-convert to Te form
    func convertToTeForm(verb:String)->String?{
        var root = ""
        var group = JPVerbGroup.one
        
        if let g = determineGroupOfVerb(verb){
            group = g
        }else{
            return nil
        }
        
        if let r = convertToRootForm(verb){
            root = r.romaji
        }else{
            return nil
        }
        
        //3. make the te form
        var composedTeForm:String?
        let last2Char = root.substringFromIndex(advance(root.endIndex, -2))
        let beforeChars = root.substringToIndex(advance(root.endIndex, -2))
        
        switch group{
        case .one:
            
            //exception
            if root == "iku"{
                return "itte"
            }
            
            switch last2Char{
            case "ku":
                composedTeForm = beforeChars + "ite"
            case "gu":
                composedTeForm = beforeChars + "ide"
            case "ru":
                composedTeForm = beforeChars + "tte"
            case "su":
                //this might be tsu
                if beforeChars.hasSuffix("t"){
                    composedTeForm = beforeChars.substringToIndex(advance(beforeChars.endIndex, -1)) + "tte"
                }else{
                    composedTeForm = beforeChars + "shite"
                }
            case "bu", "mu", "nu":
                composedTeForm = beforeChars + "nde"
            case "au", "eu", "iu", "ou", "uu":
                composedTeForm = root.substringToIndex(advance(root.endIndex, -1)) + "tte"
            default:
                return nil
            }
            
        case .two:
            composedTeForm = beforeChars + "te"
        case .three:
            composedTeForm = beforeChars.substringToIndex(advance(beforeChars.endIndex, -1)) + "ite"    //shuru or suru -> site
        }
        
        return composedTeForm
    }
    
    
    //MARK:-convert to TA fomr
    func convertToTAFrom(verb:String)->String?{
        //1. get Te form
        //2. Replace the e with a
        //        guard let teForm = convertToTeForm(verb) else{
        //            return nil
        //        }
        var teForm = ""
        if let te = convertToTeForm(verb){
            teForm = te
        }else{ return nil }
        
        return teForm.substringToIndex(advance(teForm.endIndex, -1)) + "a"
    }
    
    
    
    //MARK:- Converting to Various forms
    //3. Convert a verb to masu form
    //3.1 Past
    //3.2 Past Negative
    //3.3 Past Negative Continious
    //3.4 Past Continious
    //3.5 Present Negative
    //3.6 Present Negative Continious
    //3.7 Present Continious
    //3.8 Future
    //3.9 Future Negative
    //3.9.1 Future Negative Continious
    //3.9.2 Future Continious
    /**
    Helps conjugate a simple verbs based on given tense and parameters
    
    :param: verb       String. Either masu or root. Must be in Japanese
    :param: tense      TenseType Enum
    :param: negative   Bool
    :param: continious Bool
    
    :returns: String?
    */
    func conjugateJapaneseVerbToBasicForm(verb:String, tense:TenseType, negative:Bool = false, continious:Bool = false) -> String?{
        //get the group
        let group = determineGroupOfVerb(verb)
        //get the stem word
        let stem = convertToStemWord(verb)
        
        //if we cant find the group and the stem then its bad input
        if group == nil && stem == nil{
            return nil
        }
        
        //1. Configure tense and negative/positive
        var composed = stem!
        
        //if its continious
        if continious{
            //get the te form and add "masu" or "masen"
            if let teForm = convertToTeForm(verb){
                composed = teForm
            }else{
                return nil
            }
        }
        
        switch tense{
        case .Future:
            fallthrough
        case .Present:
            composed += (negative) ? "imasen" : "imasu"
        case .Past:
            if continious { //continuosu form = kaketeimasu
                composed += (negative) ?  "imasendeshita" : "imashita"
            }else{
                composed += (negative) ? "masendeshita" : "mashita"
            }
            
        }
        //FIXME:-Return Hiragan or Romaji
        return composed
    }
    
    
    //MARK:- Decompose JP verb to pieces
    
    /**
    Decompose the verb given to parts like Tense, Continious, Negative and the possible rootWord that can be useful to look up the translation to get the english word and use it. **The possible root word is correct when its not continious form.**
    
    :param: verb Hiragana or Kanji. Kanji gives better result
    
    :returns: VerbPartsSimple Struct that consists of the above parts
    */
    func decomposeJPVerbToSimpleParts(var verb:String) -> VerbPartsSimple?{
        //Inner functions
        //we know it can look the scope of the parent func but lets keep things simple so we might take this method out some day and we dont need to bother about the tight coupling
        func isMasuVerbIsNegative(endingMasu:String) -> Bool{
            //We are looking for the presence of masEN maseENdeshita
            if  let _ = endingMasu.rangeOfString("en", options: NSStringCompareOptions.BackwardsSearch, range: nil, locale: nil){
                return true
            }else{
                return false
            }
        }
        
        func isMasuVerbContinious(firstPart:String)->Bool{
            //check for the tei right before the masu ending
            if firstPart.hasSuffix("tei"){
                return true
            }
            return false
        }
        
        func determineTenseOfMasuVerb(endingMasu:String) -> TenseType?{
            // if the end has u then its present or future
            //if it has hita then its past
            if endingMasu.hasSuffix("u") || endingMasu.hasSuffix("en"){
                return TenseType.Present
            }else if endingMasu.hasSuffix("hita"){
                return TenseType.Past
            }else{
                //probably wont happen but okay to have it for now
                return nil
            }
        }
        
        func getPossibleRootForMasuVerb(var fullVerb:String) -> String{
            //if it is tei its hard
            //remove the TEI adn return the left over
            let verbCopy = fullVerb
            for index in masuEndidngs{
                if verb.hasSuffix(index){
                    fullVerb = verb.stringByReplacingOccurrencesOfString(index, withString: "", options: nil, range: nil)
                    break;
                }
            }
            
            //we trimmed it
            if fullVerb.hasSuffix("てい"){
                //timr the tei and return
                var possibleRoot = fullVerb.stringByReplacingOccurrencesOfString("てい", withString: "", options: nil, range: nil)
                //remove the small tsu っ
                if possibleRoot.hasSuffix("っ"){
                    possibleRoot = possibleRoot.stringByReplacingOccurrencesOfString("っ", withString: "", options: nil, range: nil)
                }
                return possibleRoot
            }else{
                //get the japanese root
               return convertToRootForm(verbCopy)!.japanese ?? verbByRemovingMasuEnding(verbCopy)!

            }
        }
        
        guard let v = getTrimmedVerbByCheckingForVerbValidity(verb) else{ return nil  //bad verb }
        verb = v
    
        let romanijedVerb = convertAnyJapaneseToRomaji(verb)
        
        //check if the verb has masu endings
        if !isVerbInMasuForm(verb){
            return nil
        }
        
        var parts = VerbPartsSimple()
        
        //it has masu ending now being decomposing using the romaji form
        let rangeOfMasu = romanijedVerb.rangeOfString("mas", options: NSStringCompareOptions.BackwardsSearch, range: nil, locale: nil)! //must have mas
        
        let endingCharIndexOfMas = rangeOfMasu.endIndex
        let remaingingEndChars = romanijedVerb.substringFromIndex(rangeOfMasu.endIndex)  //after mas-->
        let firstPart = romanijedVerb.substringToIndex(rangeOfMasu.startIndex) // before -->mas
        
        parts.negative = isMasuVerbIsNegative(remaingingEndChars)
        parts.continious = isMasuVerbContinious(firstPart)
        parts.tense = determineTenseOfMasuVerb(remaingingEndChars)
        parts.possibleRoot = getPossibleRootForMasuVerb(verb)       //its useful if we can return back the kanji
        
        return parts
    }
}



//MARK:- global functions
extension JapaneseVerbTransformer{
    /**
    Format the given verb by trimming spaces. It gives a workable verb.
    
    :param: verb verb either in japanese or romaji
    
    :returns: String? . If it is a bad input returns nil
    */
    private func getTrimmedVerbByCheckingForVerbValidity(var verb:String) -> String?{
        //prepare the verb of any abnormalities
        //remove the trailing leading whitespace
        //remove ? comma or .
        verb = verb.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "。？　、 "))
        
        if !isVerbInMasuForm(verb){
            if verb.hasSuffix("です") || verb.hasSuffix("でした") {
                //good chance its a noun or adjective
                return nil
            }
        }
        
        return verb
    }
    
    
    //2.
    /**
    Remove Masu Endings if the provided verb is proper masu form either in romaji or japanese
    
    :param: verb String
    
    :returns: String? 
    */
    private func verbByRemovingMasuEnding(var verb:String)->String?{
        if !isVerbInMasuForm(verb){
            return nil
        }
        
        for index in masuEndidngs{
            if verb.hasSuffix(index){
                verb = verb.stringByReplacingOccurrencesOfString(index, withString: "", options: nil, range: nil)
                return verb
            }
        }
        
        //if its romaji
        for index in masuEndingsRomaji{
            if verb.hasSuffix(index){
                verb = verb.stringByReplacingOccurrencesOfString(index, withString: "", options: nil, range: nil)
                return verb
            }
        }
        
        //not possible
        return nil
    }
    
    
    
    //3.
    /**
    Determine weather a given verb is in masu ending or not
    
    :param: verb String
    
    :returns: Bool
    */
    private func isVerbInMasuForm(verb:String)->Bool{
        //checking for japanese frms
        for index in masuEndidngs{
            if verb.hasSuffix(index){
                return true
            }
        }
        //checking for romanized forms
        for index in masuEndingsRomaji{
            if verb.hasSuffix(index){
                return true
            }
        }
        return false
    }
    
    //4.
    /**
    determine if the verb is in root form
    
    :param: verb String
    
    :returns: Bool
    */
    private func isVerbInRootForm(verb:String)->Bool{
        //if the last character of the verb is in "U" ending
        //if the ending is not id desu forms
        //TODO:-research more
        let romaji = convertAnyJapaneseToRomaji(verb)
        
        for index in desuEndings{
            if verb.hasSuffix(index){
                return false
            }
        }
        
        if romaji.substringFromIndex(advance(romaji.endIndex, -1)).lowercaseString == "u" {
            return true
        }
        return false
    }
    
}



//MARK:- Conveinence methods for string transformation
//This extension is dependent on another library
extension JapaneseVerbTransformer{
    
    func convertKanjiToHiragana(kanji:String)->String{
        return (kanji as NSString).stringByTransliteratingJapaneseToHiragana()
    }
    
    //TO Romaji
    func convertHiraganaToRomaji(hiragana:String) -> String{
        return (hiragana as NSString).stringByTransliteratingJapaneseToRomaji()
    }
    
    func convertKatakanaToRomaji(katakana:String)->String{
        return (katakana as NSString).stringByTransliteratingJapaneseToRomaji()
    }
    
    func convertKanjiToRomaji(kanji:String) -> String{
        return (kanji as NSString).stringByTransliteratingJapaneseToRomaji()
    }
    
    //From Romaji
    func convertRomajiToHiragana(romaji:String) -> String{
        return (romaji as NSString).stringByTransliteratingRomajiToHiragana()
    }
    
    func convertRomajiToKatakana(romaji:String)->String{
        return (romaji as NSString).stringByTransliteratingRomajiToKatakana()
    }
    
    
    //Convenience functions  Katakana = hiragana, kanji-> katakana
    func convertKanjiToKatakana(kanji:String) -> String{
        //Kanji->(Hiragana)-> Romaji -> Katakana
        return convertRomajiToKatakana(convertKanjiToRomaji(kanji))
    }
    
    func convertHiraganaToKatakana(hiragana:String)->String{
        return convertRomajiToKatakana(convertHiraganaToRomaji(hiragana))
    }
    
    func convertKatakanaToHiragana(katakana:String) -> String{
        return convertRomajiToHiragana(convertKatakanaToRomaji(katakana))
    }
    
    //All mighty
    func convertAnyJapaneseToRomaji(japanese:String)->String{
        return japanese.stringByTransliteratingJapaneseToRomaji()
    }
}


extension String{
    func log(){
        println(self)
    }
    
    //For ease in swift 1.2
    //swift 2 does allow something like string.characters.contains("") but swift 1.2 doesnot
    func containsChar(char:String)->Bool{
        
        guard count(char) == 1 else{ return false }
        
        for character in self{
            if "\(character)" == char{
                return true
            }
        }

        return false
    }
}
