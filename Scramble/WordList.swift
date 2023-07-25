//
//  WordList.swift
//  Scramble
//
//  Created by Nikola Jovicevic on 6.7.23..
//

import Foundation

struct WordList {
    private(set) var wordListGenerating: [String]
    private(set) var wordListSearching: [String]
    
    init() {
        wordListGenerating = []
        wordListSearching = []
        
        if let filepath = Bundle.main.path(forResource: "wordlist_generating", ofType: "txt") {
            do {
                let contents = try String(contentsOfFile: filepath)
                wordListGenerating = contents.components(separatedBy: .newlines)
                for index in wordListGenerating.indices {
                    wordListGenerating[index] = wordListGenerating[index].uppercased()
                }
            } catch {
                print("Couldn't find the wordlist_generating file!")
            }
        }
        
        if let filepath = Bundle.main.path(forResource: "wordlist", ofType: "txt") {
            do {
                let contents = try String(contentsOfFile: filepath)
                wordListSearching = contents.components(separatedBy: .newlines)
                for index in wordListSearching.indices {
                    wordListSearching[index] = wordListSearching[index].uppercased()
                }
            } catch {
                print("Couldn't find the wordlist_searching file!")
            }
        }
    }
}
