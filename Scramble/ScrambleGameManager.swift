//
//  Scramble.swift
//  Scramble
//
//  Created by Nikola Jovicevic on 4.7.23..
//

import SwiftUI

class ScrambleGameManager: ObservableObject {
    typealias Letter = ScrambleGame.Letter
    
    private static func createScrambleGame() -> ScrambleGame {
        ScrambleGame()
    }
    
    @Published private var model = createScrambleGame()
    
    var score: Int { model.score * 10 }
    
    var alertText: String { model.alertText }
    
    var alertTextColor: Color { model.alertTextColor }
    
    var letters: [Letter] { model.letters }
    
    var letterColor: [Color] { model.letterColor }
    
    var chosenLetterColor: Color { model.chosenLetterColor }
    
    var chosenLetters: [Letter] { model.chosenLetters }
    
    var seenWords: [String] { Array(model.seenWords).sorted() }
    
    var definitions: Dictionary<String, Set<String>> = [:]
    
    // MARK: Intent(s)
    
    func choose(_ letter: Letter) {
        model.choose(letter)
    }
    
    func shuffle() {
        model.shuffle()
    }
    
    func submit() {
        if model.submit() {
            definitionsOf(model.currentWord())
        }
    }
    
    func setColorToDefault(_ isHinted: Bool) {
        model.setColorToDefault(isHinted)
    }
    
    func restart() {
        model = ScrambleGameManager.createScrambleGame()
        definitions = [:]
    }
    
    func randomNonFoundWord() {
        model.randomNonFoundWord()
    }
    
    func isChosenLetter(id: Int) -> Bool {
        model.isChosenLetter(id)
    }
    
    func definitionsOf(_ word: String) {
        model.definitionsOf(word) { result in
            self.definitions[word] = result
        }
    }
}
