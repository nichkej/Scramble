//
//  ScrambleGame.swift
//  Scramble
//
//  Created by Nikola Jovicevic on 4.7.23..
//

import SwiftUI

struct ScrambleGame {
    private static var wordListManager = WordList()
    private var wordList = wordListManager.wordListGenerating
    // use Set instead of Array to optimize pattern matching (when searching guessed words)
    private var wordListSet: Set<String> = Set(wordListManager.wordListSearching)
    private var charactersToUse: [String]
    private(set) var seenWords: Set<String> = []
    
    private(set) var letters: [Letter]
    private(set) var chosenLetters: [Letter]
    private(set) var letterColor: [Color] = []
    // shortens implementation of setting color after submit
    private(set) var chosenLetterColor: Color = Color.black
    
    private let apiReader = APIReader()
    
    private(set) var score = 0
    
    private(set) var alertText = "Alert text goes here"
    private(set) var alertTextColor = Color.clear
    
    mutating func choose(_ letter: Letter) {
        if let chosenIndex = letters.firstIndex(where: {$0.contentId == letter.contentId}) {
            // insert a card at the end of chosen cards array if not already there
            letters.remove(at: chosenIndex)
            chosenLetters.append(letter)
        } else if let chosenIndex = chosenLetters.firstIndex(where: {$0.contentId == letter.contentId}) {
            // push card back to its appropriate position in the non-chosen cards array
            chosenLetters.remove(at: chosenIndex)
            var indexToPut = letters.count
            for newIndex in (0 ..< letters.count).reversed() {
                if letters[newIndex].contentId > letter.contentId {
                    indexToPut = newIndex
                }
            }
            letters.insert(letter, at: indexToPut)
        }
    }
    
    func currentWord() -> String {
        var currentWord = ""
        for letter in chosenLetters {
            currentWord += letter.content
        }
        return currentWord
    }
    
    mutating func submit() -> Bool {
        var flag = false
        
        let currentWord = currentWord()
        
        setColorToDefault(false)
        
        // don't consider short words and words already in the set as valid
        if currentWord.count > 2
            && !seenWords.contains(currentWord)
            && wordListSet.contains(currentWord) {
            seenWords.insert(currentWord)
            score += currentWord.count
            chosenLetterColor = LetterConstants.correctWordColor
            alertText = "Great!"
            flag = true
        } else if seenWords.contains(currentWord) {
            chosenLetterColor = LetterConstants.guessedWordColor
            alertText = "You've already entered this word."
        } else {
            chosenLetterColor = LetterConstants.invalidWordColor
            alertText = "Mmm... I can't find it in the dictionary."
        }
        
        for letter in chosenLetters {
            letterColor[letter.id] = chosenLetterColor
        }
        alertTextColor = chosenLetterColor
        
        return flag
    }
    
    mutating func setColorToDefault(_ isHinted: Bool) {
        chosenLetterColor = LetterConstants.defaultWordColor
        // doesn't reset words that are hinted to default color if isHinted = true
        for index in letterColor.indices {
            if isHinted
                && letterColor[index] == LetterConstants.hintWordColor {
                continue
            }
            letterColor[index] = chosenLetterColor
        }
        alertTextColor = Color.clear
    }
    
    mutating func shuffle() {
        if letters.isEmpty {
            return
        }
        
        // used to preserve contentId later
        let previousLetters = letters
        repeat {
            letters.shuffle()
        } while (letters.elementsEqual(previousLetters))
        
        // preserve contentId in the new array not to break choose function
        for index in letters.indices {
            letters[index].contentId = previousLetters[index].contentId
        }
    }
    
    mutating func randomNonFoundWord() {
        // store sorted ids of cards containing given letters
        var letterIds : Dictionary<String, [Int]> = [:]
        for letter in letters {
            if letterIds[letter.content] != nil {
                var tmp: [Int] = letterIds[letter.content]!
                tmp.append(letter.id)
                letterIds[letter.content] = tmp
            } else {
                letterIds[letter.content] = [letter.id]
            }
        }
        for letter in chosenLetters {
            if letterIds[letter.content] != nil {
                var tmp: [Int] = letterIds[letter.content]!
                tmp.append(letter.id)
                letterIds[letter.content] = tmp
            } else {
                letterIds[letter.content] = [letter.id]
            }
        }
        
        for (key, _) in letterIds {
            letterIds[key] = letterIds[key]!.sorted()
        }
        
        // find all words user didn't already find and keep them in an array
        var resultWordIndices: [Int] = []
        var nonFoundWords: [String] = []
        for word in wordListSet {
            if word.count < 3 || seenWords.contains(word) {
                continue
            }
            let wordIndices = findWord(word, in: letterIds)
            if !wordIndices.isEmpty {
                nonFoundWords.append(word)
            }
        }
        
        if !nonFoundWords.isEmpty {
            // returns a random word user hasn't already found
            resultWordIndices = findWord(nonFoundWords[Int.random(in: nonFoundWords.indices)], in: letterIds)
            
            for index in resultWordIndices {
                letterColor[index] = Color.yellow
            }
        }
    }
    
    func findWord(_ word: String, in ids: Dictionary<String, [Int]>) -> [Int] {
        // can't directly alter value of dictionary as it is treated as value type
        var mutableIds = ids
        var result: [Int] = []
        
        // return positions of letters than can constitute given word, such that their ids are as small as possible
        for char in word {
            if mutableIds[String(char)] == nil
                || mutableIds[String(char)]!.isEmpty {
                return []
            }
            // always take leftmost ids in order to preserve same letter choices for different hints
            // e. g. WORWD should always produce [W][O][R]W[D] as hint, not W[O][R][W][D]
            // although both the above are valid, we want consistent results
            result.append(mutableIds[String(char)]![0])
            var tmp: [Int] = mutableIds[String(char)]!
            tmp.remove(at: 0)
            mutableIds[String(char)] = tmp
        }
        
        return result
    }
    
    func isChosenLetter(_ id: Int) -> Bool {
        chosenLetters.contains(where: { letter in
            letter.id == id
        })
    }
    
    func definitionsOf(_ word: String, completion: @escaping (Set<String>) -> ()) {
        var resultDefinitions: Set<String> = []
        
        apiReader.getJSON(urlString: "https://api.dictionaryapi.dev/api/v2/entries/en/\(word.lowercased())") { result in
            if let result = result {
                for meaningObject in result {
                    for meaning in meaningObject.meanings {
                        for definitions in meaning.definitions {
                            resultDefinitions.insert(meaning.partOfSpeech + ": " + definitions.definition)
                        }
                    }
                }
            }
            // can't return definitions from function, since getJSON is asynchronous
            // instead do completion block when resultDefinitions are accumulated
            // completion inside another completion block
            completion(resultDefinitions)
        }
    }
    
    init() {
        letters = []
        chosenLetters = []
        
        // generates starting letters
        // pick some valid 10 letter word and shuffle it
        let chosenWord = wordList[Int.random(in: 0 ..< wordList.count)]
        charactersToUse = []
        for c in chosenWord {
            charactersToUse.append(String(c))
        }
        charactersToUse.shuffle()
        
        var ids: [Int] = []
        for index in 0 ..< 10 {
            ids.append(index)
        }
        ids.shuffle()
        
        for index in 0 ..< 10 {
            letters.append(Letter(content: charactersToUse[index], id: ids[index], contentId: index))
            letterColor.append(LetterConstants.defaultWordColor)
        }
    }
    
    struct Letter: Identifiable, Equatable {
        let content: String
        var id: Int
        var contentId: Int
    }
    
    private struct LetterConstants {
        static let defaultWordColor = Color.purple
        static let correctWordColor = Color.green
        static let invalidWordColor = Color.red
        static let guessedWordColor = Color.cyan
        static let hintWordColor = Color.yellow
    }
}
