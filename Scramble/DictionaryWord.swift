//
//  DictionaryWord.swift
//  Scramble
//
//  Created by Nikola Jovicevic on 9.7.23..
//

import Foundation

struct DictionaryWord: Decodable {
    struct Meaning: Decodable {
        let partOfSpeech: String
        struct Definition: Decodable {
            let definition: String
        }
        let definitions: [Definition]
    }
    let meanings: [Meaning]
}
