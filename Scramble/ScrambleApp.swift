//
//  ScrambleApp.swift
//  Scramble
//
//  Created by Nikola Jovicevic on 4.7.23..
//

import SwiftUI

@main
struct ScrambleApp: App {
    var body: some Scene {
        WindowGroup {
            let game = ScrambleGameManager()
            ScrambleGameView(game: game)
        }
    }
}
