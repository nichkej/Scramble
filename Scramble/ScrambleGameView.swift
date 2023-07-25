//
//  ScrambleGameView.swift
//  Scramble
//
//  Created by Nikola Jovicevic on 4.7.23..
//

import SwiftUI

struct ScrambleGameView: View {
    @ObservedObject var game: ScrambleGameManager
    @Namespace var letterNamespace
    
    @State private var isClickableLetter = Array.init(repeating: true, count: 10)
    
    @State private var showingGuessedWords = false
    @State private var isHinted = false
    // submit animation transitioning controller
    @State private var isTransitioning = 0
    @State private var definitions: [String] = []
    @State private var showingDefinitionsForWord = ""
    @State private var transitionAnimationStarted = Date()
    
    var body: some View {
        VStack {
            hint
            score
            Spacer()
            chosenLetters
            alertText
            Spacer()
            letters
            controlButtons
        }
        .padding()
    }
    
    var hint: some View {
        Button(action: {
            if !isHinted {
                isHinted = true
                // if submit animation is not over, wait for it to finish and then start animation
                DispatchQueue.main.asyncAfter(deadline: .now() + (2 * LetterConstants.submitAnimationDuration - Date().timeIntervalSince(transitionAnimationStarted)) * CGFloat(isTransitioning)) {
                    withAnimation(.easeInOut(duration: LetterConstants.hintAnimationDuration)) {
                        game.setColorToDefault(false)
                        game.randomNonFoundWord()
                    }
                }
            }
        }) {
            Text("HINT")
                .padding()
        }
    }
    
    var score: some View {
        Button(action: {
            showingGuessedWords = true
        }) {
            Text(String(game.score))
                .font(Font.system(size: ScoreConstants.fontSize))
                .transition(AnyTransition.asymmetric(insertion: AnyTransition.offset(y: ScoreConstants.transitionOffsetY), removal: AnyTransition.opacity))
                .id("Score"+String(game.score)) // id = "Score" + value, to generate unique renderer identifier
                .foregroundColor(.black)
        }
        .popover(isPresented: $showingGuessedWords) {
            guessedWordList
        }
        .padding(.top, 50)
    }
    
    var guessedWordList: some View {
        ZStack {
            if showingDefinitionsForWord == "" {
                VStack {
                    if game.seenWords.isEmpty {
                        Text("You haven't guessed a word!")
                            .font(Font.system(size: LetterConstants.fontSize))
                            .foregroundColor(LetterConstants.backgroundColor)
                            .fontWeight(.bold)
                    } else {
                        Text("Gussed words")
                            .font(Font.system(size: LetterConstants.titleFontSize))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical)
                        ScrollView(showsIndicators: false) {
                            LazyVStack {
                                ForEach(game.seenWords, id: \.self) { word in
                                    HStack {
                                        Button(action: {
                                            showingDefinitionsForWord = word
                                        }){
                                            Text(word)
                                                .font(Font.system(size: LetterConstants.fontSize))
                                                .foregroundColor(Color.black)
                                                .fontWeight(.medium)
                                                .padding(.bottom, 3)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .scrollBounceBehavior(.basedOnSize)
                    }
                }
            } else {
                VStack {
                    Text("Definitions\nof " + showingDefinitionsForWord.uppercased())
                        .font(Font.system(size: LetterConstants.titleFontSize))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical)
                    ScrollView(showsIndicators: false) {
                        LazyVStack {
                            ForEach(Array(game.definitions[showingDefinitionsForWord] ?? []), id: \.self) { definition in
                                Text(definition)
                                    .font(Font.system(size: LetterConstants.definitionFontSize, design: .serif))
                                    .foregroundColor(Color.black)
                                    .fontWeight(.medium)
                                    .italic()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.bottom, 5)
                            }
                        }
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    Button(action: {
                        showingDefinitionsForWord = ""
                    }) {
                        Text("Back to guessed words")
                    }
                    .padding(.top)
                }
            }
        }
        .padding(30)
    }
    
    var chosenLetters: some View {
        HStack(spacing: 3) {
            ForEach(game.chosenLetters) { letter in
                LetterView(letter: letter, color: game.letterColor[letter.id])
                    .frame(maxWidth: 75)
                    .matchedGeometryEffect(id: letter.id, in: letterNamespace, isSource: game.isChosenLetter(id: letter.id))
                    .transition(AnyTransition.scale(scale: 1))
                    .onTapGesture {
                        if isClickableLetter[letter.id] {
                            isClickableLetter[letter.id] = false
                            // animations start from top-left corner and produce sort of 'glitchy' effect
                            // in order to surpass this, wait for parent to be drawn and schedule animation
                            // for 0.01 seconds (or any other unnoticable timeframe)
                            DispatchQueue.main.asyncAfter (deadline: .now() + 0.01) {
                                withAnimation(.easeInOut(duration: LetterConstants.transferAnimationDuration)) {
                                    game.choose(letter)
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + LetterConstants.transferAnimationDuration) {
                                isClickableLetter[letter.id] = true
                            }
                        }
                    }
            }
        }
        .padding()
    }
    
    var letters: some View {
        let columns = [GridItem(), GridItem(), GridItem(), GridItem(), GridItem()]
        
        return LazyVGrid(columns: columns) {
            ForEach(game.letters) { letter in
                LetterView(letter: letter, color: game.letterColor[letter.id])
                    .matchedGeometryEffect(id: letter.id, in: letterNamespace, isSource: !game.isChosenLetter(id: letter.id))
                    .transition(AnyTransition.scale(scale: 1))
                    .onTapGesture {
                        if isClickableLetter[letter.id] {
                            isClickableLetter[letter.id] = false
                            // same logic of asyncing after is applied in chosenLetters (refer to that)
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                                withAnimation(.easeInOut(duration: LetterConstants.transferAnimationDuration)) {
                                    game.choose(letter)
                                }
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + LetterConstants.transferAnimationDuration) {
                                isClickableLetter[letter.id] = true
                            }
                        }
                    }
            }
        }
        .padding()
    }
    
    var alertText: some View {
        Text(game.alertText)
            .padding(0)
            .foregroundColor(game.alertTextColor)
    }
    
    var shuffle: some View {
        Button(action: {
            withAnimation {
                game.shuffle()
            }
        }) {
            Text("Shuffle")
        }
    }
    
    var submit: some View {
        Button(action: {
            isClickableLetter = Array.init(repeating: false, count: 10)
            isHinted = false
            isTransitioning = 1
            transitionAnimationStarted = Date()
            withAnimation(.easeInOut(duration: LetterConstants.submitAnimationDuration)) {
                game.submit()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + LetterConstants.submitAnimationDuration) {
                withAnimation(.easeInOut(duration: LetterConstants.submitAnimationDuration)) {
                    // wait for colors to transition before reverting them back to default color
                    DispatchQueue.main.asyncAfter(deadline: .now() + LetterConstants.submitAnimationDuration) {
                        isTransitioning = 0
                        isClickableLetter = Array.init(repeating: true, count: 10)
                    }
                    game.setColorToDefault(isHinted)
                }
            }
        }) {
            Text("Submit")
        }
    }
    
    var restart: some View {
        Button(action: {
            // reset variables to default values
            isTransitioning = 0
            isHinted = false
            showingGuessedWords = false
            showingDefinitionsForWord = ""
            withAnimation {
                game.restart()
            }
        }) {
            Text("New Game")
        }
    }
    
    var controlButtons: some View {
        HStack {
            shuffle
            Spacer()
            submit
            Spacer()
            restart
        }
        .padding(.horizontal, 20)
    }
}

struct LetterView: View {
    let letter: ScrambleGame.Letter
    let color: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: LetterConstants.cornerRadius)
                .foregroundColor(color)
                .aspectRatio(contentMode: .fit)
                .transition(AnyTransition.opacity)
            Text(letter.content)
                .font(Font.system(size: LetterConstants.fontSize))
                .fontWeight(.bold)
                .foregroundColor(LetterConstants.fontColor)
        }
    }
}

private struct LetterConstants {
    static let cornerRadius: CGFloat = 6
    static let fontSize: CGFloat = 22
    static let titleFontSize: CGFloat = 35
    static let definitionFontSize: CGFloat = 18
    static let backgroundColor: Color = Color.purple
    static let fontColor: Color = Color.white
    static let transferAnimationDuration: CGFloat = 0.35
    static let submitAnimationDuration: CGFloat = 0.8
    static let hintAnimationDuration: CGFloat = 0.8
}

private struct ScoreConstants {
    static let fontSize: CGFloat = 50
    static let transitionOffsetY: CGFloat = 30
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let game = ScrambleGameManager()
        ScrambleGameView(game: game)
    }
}
