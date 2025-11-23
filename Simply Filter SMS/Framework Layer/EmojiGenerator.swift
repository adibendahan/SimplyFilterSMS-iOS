//
//  EmojiGenerator.swift
//  Simply Filter SMS
//
//  Created by Assistant on 22/11/2025.
//

import Foundation

enum EmojiGenerator {
    static func randomEmoji() -> String {
        // Common emoji blocks (BMP + SMP)
        let ranges: [ClosedRange<Int>] = [
            0x1F300...0x1F5FF, // Misc Symbols and Pictographs
            0x1F600...0x1F64F, // Emoticons
            0x1F680...0x1F6FF, // Transport and Map
            0x1F700...0x1F77F, // Alchemical Symbols
            0x1F780...0x1F7FF, // Geometric Shapes Extended
            0x1F800...0x1F8FF, // Supplemental Arrows-C
            0x1F900...0x1F9FF, // Supplemental Symbols and Pictographs
            0x1FA00...0x1FA6F, // Chess Symbols, Symbols & Pictographs Extended-A (partial)
            0x1FA70...0x1FAFF, // Symbols & Pictographs Extended-A (rest)
            0x2600...0x26FF,   // Misc Symbols
            0x2700...0x27BF    // Dingbats
        ]

        // Try a few times to avoid invalid scalars or non-rendering codepoints
        for _ in 0..<8 {
            let range = ranges.randomElement()!
            let value = Int.random(in: range)
            if let scalar = UnicodeScalar(value) {
                let s = String(scalar)
                if s.unicodeScalars.first?.properties.isEmojiPresentation == true ||
                    s.unicodeScalars.first?.properties.isEmoji == true {
                    return s
                }
            }
        }
        return "🙂"
    }
}
