//
//  DecisionService.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import Foundation

/// One step of the animation: show `text` for `duration` seconds.
struct DrawFrame: Equatable {
    let text: String
    let duration: TimeInterval
}

/// The full result of a draw, decided once, before any animation starts.
/// The UI just plays the frames; the last one is always the winner.
struct DrawPlan {
    let winnerIndex: Int
    let winner: String
    let frames: [DrawFrame]
}

struct DecisionService {

    private static let minimumFrameCount = 18
    private static let fastestFrameDuration: TimeInterval = 0.06
    private static let slowestFrameDuration: TimeInterval = 0.45

    /// Normal entry point: uses the system random number generator.
    func makeDrawPlan(for decision: Decision) throws -> DrawPlan {
        var generator = SystemRandomNumberGenerator()
        return try makeDrawPlan(for: decision, using: &generator)
    }

    /// The generator is a parameter so tests can control randomness if needed.
    func makeDrawPlan<G: RandomNumberGenerator>(
        for decision: Decision,
        using generator: inout G
    ) throws -> DrawPlan {
        try decision.validate()

        let options = decision.options

        // randomElement escolhe com probabilidade igual para cada índice.
        guard let winnerIndex = options.indices.randomElement(using: &generator) else {
            throw DecisionError.notEnoughOptions
        }

        // Percorremos as opções em ordem circular (como uma roleta) e calculamos
        // os índices "de trás pra frente", para a última sempre ser a vencedora.
        let frameCount = max(Self.minimumFrameCount, options.count * 2)
        let frames = (0..<frameCount).map { position -> DrawFrame in
            let stepsBeforeEnd = frameCount - 1 - position
            let rawIndex = winnerIndex - stepsBeforeEnd
            let optionIndex = ((rawIndex % options.count) + options.count) % options.count

            // progress vai de 0 a 1; elevar a 2.5 faz a duração crescer devagar
            // no começo e rápido no fim: começa veloz e desacelera.
            let progress = Double(position) / Double(frameCount - 1)
            let range = Self.slowestFrameDuration - Self.fastestFrameDuration
            let duration = Self.fastestFrameDuration + range * pow(progress, 2.5)

            return DrawFrame(text: options[optionIndex], duration: duration)
        }

        return DrawPlan(winnerIndex: winnerIndex, winner: options[winnerIndex], frames: frames)
    }
}

