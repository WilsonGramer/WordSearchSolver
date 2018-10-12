import Foundation

extension Array where Element: Equatable {
    /// Finds all indexes of the given element in the array.
    func indexes(of element: Element) -> [Int] {
        return self.enumerated().filter({ element == $0.element }).map({ $0.offset })
    }
}

extension Collection {
    /// Returns the element at the specified index iff it is
    /// within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

extension String {
    /// Allows access to individual characters of a string using
    /// a numerical subscript.
    subscript (i: Int) -> Character {
        return self[index(startIndex, offsetBy: i)]
    }
}

/// A word search; ie. a two-dimensional array of characters.
typealias WordSearch = [[Character]]

/// A position in a two-dimensional coordinate plane.
typealias Position = (x: Int, y: Int)

extension Array where Element == Position {
    /// Orders the positions from least to greatest. A greater
    /// x coordinate takes precedence over a greater y
    /// coordinate.
    func ordered() -> [Position] {
        return self.sorted { (first, second) -> Bool in
            if first.x == second.x {
                return first.y < second.y
            } else {
                return first.x < second.x
            }
        }
    }
}

/// A representation of the range between an initial position
/// and a final position.
struct PositionRange: Equatable, CustomStringConvertible {
    
    var initialPosition: Position
    var finalPosition: Position
    
    init(from initialPosition: Position, to finalPosition: Position) {
        self.initialPosition = initialPosition
        self.finalPosition = finalPosition
    }
    
    init?(fromPositions positions: [Position]) {
        if positions.count <= 2 {
            return nil
        } else {
            let ordered = positions.ordered()
            self.init(from: ordered.first!, to: ordered.last!)
        }
    }
    
    static func == (lhs: PositionRange, rhs: PositionRange) -> Bool {
        return (
            lhs.initialPosition == rhs.initialPosition
            && lhs.finalPosition == rhs.finalPosition
        )
    }
    
    var description: String {
        return "(\(self.initialPosition.x),\(self.initialPosition.y))...(\(self.finalPosition.x),\(self.finalPosition.y))"
    }
}

/// A dictionary where all the positions of a character are
/// mapped to the character.
typealias CharacterPositionMap = [Character : [Position]]

/// Similar to a `CharacterPositionMap`, but in order.
typealias WordPositionMap = [(character: Character, position: Position)]

/// Finds all the locations of `character` in the given
/// word search.
func find(character: Character, in wordSearch: WordSearch) -> [Position] {
    var result = [Position]()
    
    // Iterates over each row in the word search
    for (rowIndex, row) in wordSearch.enumerated() {
        /// Finds all positions in the current row where this
        /// character exists
        let indexesOfCharacterInRow = row.indexes(of: character)
        
        for columnIndex in indexesOfCharacterInRow {
            result.append((columnIndex, rowIndex))
        }
    }
    
    return result
}

/// Returns all the positions immediately adjacent to the given position.
func getPositions(adjacentTo position: Position, in wordSearch: WordSearch) -> [Position] {
    let px = position.x
    let py = position.y
    
    return [
        (px - 1, py - 1), (px, py - 1), (px + 1, py - 1),
        (px - 1, py), (px + 1, py),
        (px - 1, py + 1), (px, py + 1), (px + 1, py + 1)
    ].filter {
        // Only return the positions that exist in the word search!
        // (This is to prevent against crashes where the given
        // position is on the edge of the word search and has less
        // than 8 adjacent positions)
        wordSearch[safe: $0.y]?[safe: $0.x] != nil
    }
}

/// Returns all the characters immediately adjacent to the given position
/// as a `CharacterPositionMap`.
func getCharacters(adjacentTo position: Position, in wordSearch: WordSearch) -> CharacterPositionMap {
    var result = CharacterPositionMap()
    
    let immediateSurroundings = getPositions(adjacentTo: position, in: wordSearch)
    for position in immediateSurroundings {
        // Get the character at the position and add it to the result
        let characterAtPosition = wordSearch[position.y][position.x]
        result[characterAtPosition, default: []].append(position)
    }
    
    return result
}

/// Finds every occurance of the given character in the given word and
/// returns the indexes at which it is located in the word.
func getAllPositions(of character: Character, in word: String) -> [Int] {
    var result = [Int]()
    
    for (index, character) in word.enumerated() {
        if word.contains(character) { result.append(index) }
    }
    
    return result
}

/// Finds the given word in the given word search and returns its
/// location as a WordPositionMap, or `nil` if the word cannot be
/// found.
func find(word: String, in wordSearch: WordSearch) -> WordPositionMap? {
    var result = WordPositionMap()
    var resultAsWord = ""
    
    // Search the word search for all positions of the first character in the target
    // word, and iterate over them
    let firstCharacterPositions = find(character: word.first!, in: wordSearch)
    firstCharacterLoop: for firstCharacterPosition in firstCharacterPositions {
        /// Find all characters adjacent to this character position that are equal to
        /// the second character of the target word
        let adjacentCharacters = getCharacters(adjacentTo: firstCharacterPosition, in: wordSearch).filter { word[1] == $0.key }
        
        if adjacentCharacters.isEmpty {
            // The second character in the target word is not adjacent to this
            // position; move on to the next position
            continue firstCharacterLoop
        } else {
            // The second character in the target word is adjacent to this
            // position; now "scan" all the letters in that direction and
            // determine if the target word is found
            for (character, positions) in adjacentCharacters {
                for position in positions {
                    /// Reset the result to the first letter in the target word
                    func resetResult() {
                        result = [
                            (word.first!, firstCharacterPosition),
                            (character, position)
                        ]
                        resultAsWord = String([word.first!, character])
                    }
                    resetResult()
                    
                    /// Calculate which direction we should "scan" for the rest of the target word
                    let slope = (dx: position.x - firstCharacterPosition.x, dy: position.y - firstCharacterPosition.y)
                    
                    var nextPosition = position
                    while resultAsWord.count < word.count {
                        // "Scan" each letter in the direction of the slope, and add it to the
                        // result until there are n number of letters in the result, where n
                        // is the number of letters in the target word
                        nextPosition = (x: nextPosition.x + slope.dx, y: nextPosition.y + slope.dy)
                        
                        if let characterAtPosition = wordSearch[safe: nextPosition.y]?[safe: nextPosition.x] {
                            result.append((characterAtPosition, nextPosition))
                            resultAsWord.append(characterAtPosition)
                        } else {
                            // We've hit the edge of the word search, so the word can't exist
                            // at this location! Reset & move on to the next adjacent character
                            resetResult()
                            continue firstCharacterLoop
                        }
                    }
                    
                    if resultAsWord == word {
                        // The word was found!
                        return result
                    } else {
                        // The word was not found; reset the result and move on to the next
                        // adjacent character
                        resetResult()
                        continue firstCharacterLoop
                    }
                }
            }
        }
    }
    
    // If we got to this point without the result being returned, then
    // the word does not exist in the word search. Return nil instead
    return nil
}

/// Finds every word given in the given word search.
func solve(_ wordSearch: WordSearch, for wordsToFind: [String]) -> [String : PositionRange] {
    return wordsToFind.reduce(into: [:]) { result, word in
        if let characterPositions = find(word: word, in: wordSearch), let wordRange = PositionRange(fromPositions: characterPositions.map { $0.position }) {
            result[word] = wordRange
        }
    }
}

let wordSearch: WordSearch = [
    ["J", "F", "U", "A", "C", "T", "P", "Z", "S", "J", "I", "E", "D", "T", "J"],
    ["A", "J", "K", "O", "Y", "F", "E", "C", "G", "D", "F", "L", "T", "R", "J"],
    ["O", "Y", "R", "B", "R", "G", "A", "K", "E", "M", "V", "C", "A", "L", "P"],
    ["L", "R", "L", "M", "H", "R", "O", "N", "C", "K", "P", "I", "C", "V", "F"],
    ["Y", "M", "B", "O", "E", "I", "K", "I", "O", "O", "V", "C", "I", "M", "K"],
    ["V", "X", "P", "C", "H", "R", "C", "C", "W", "D", "P", "I", "T", "P", "N"],
    ["E", "M", "R", "S", "N", "A", "I", "L", "S", "S", "T", "U", "K", "Z", "B"],
    ["M", "O", "P", "V", "I", "J", "F", "J", "M", "X", "J", "L", "L", "M", "K"],
    ["W", "F", "D", "F", "Y", "Z", "R", "A", "B", "M", "Q", "H", "T", "Y", "S"],
    ["P", "A", "I", "E", "I", "P", "R", "P", "Q", "L", "D", "Y", "A", "R", "Q"],
    ["X", "T", "I", "R", "O", "T", "W", "T", "T", "L", "W", "X", "A", "F", "I"],
    ["M", "P", "V", "W", "S", "G", "O", "G", "R", "S", "M", "L", "S", "Z", "Z"],
    ["K", "A", "E", "J", "U", "T", "W", "Z", "F", "O", "L", "L", "Q", "L", "Q"],
    ["F", "R", "A", "D", "N", "E", "L", "A", "C", "O", "L", "R", "J", "D", "N"],
    ["A", "P", "V", "W", "F", "R", "D", "O", "C", "M", "Y", "D", "H", "I", "J"]
]

let wordsToFind = [
    "calendar",
    "pocket",
    "first",
    "scarecrow",
    "pie",
    "tacit",
    "icicle",
    "smart",
    "collar",
    "snails"
].map { $0.uppercased() }

let searched = solve(wordSearch, for: wordsToFind)
let percentFound = Int(Double(searched.count) / Double(wordsToFind.count) * 100)
let s = "FOUND \(searched.count) OUT OF \(wordsToFind.count) WORDS (\(percentFound)%):"
print(s)
print(String(repeating: "=", count: s.count) + "\n")

for (word, range) in searched {
    print("\(word): \(range)")
}

let wordsNotFound = wordsToFind.filter { searched[$0] == nil }
if !(wordsNotFound.isEmpty) {
    print("\nNOT FOUND: \(wordsNotFound.joined(separator: ", "))")
}
