//
//  DecisionServiceTests.swift
//  DecideAiTests
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import XCTest
@testable import DecideAi

// MARK: - Testes do serviço de sorteio (DecisionService)

/// Testes unitários para `DecisionService` e a geração do `DrawPlan`.
/// Foco: garantir propriedades importantes do sorteio/animação (protótipo v2):
/// vencedor consistente com o último frame, desaceleração das trocas, pausa final e erro.
final class DecisionServiceTests: XCTestCase {

    private let service = DecisionService()

    /// Helper para criar rapidamente uma decisão válida com as opções informadas.
    private func makeDecision(options: [String]) throws -> Decision {
        var decision = Decision(question: "O que comer?")
        for option in options { try decision.addOption(option) }
        return decision
    }

    /// Sortear com menos de 2 opções deve falhar com `.notEnoughOptions`.
    func testDrawFailsWithFewerThanTwoOptions() throws {
        let decision = try makeDecision(options: ["Pizza"])

        XCTAssertThrowsError(try service.makeDrawPlan(for: decision)) { error in
            XCTAssertEqual(error as? DecisionError, .notEnoughOptions)
        }
    }

    /// O último frame da animação deve ser sempre o vencedor definido no plano.
    /// Repetimos várias vezes para aumentar confiança diante da aleatoriedade.
    func testLastFrameIsAlwaysTheWinner() throws {
        let decision = try makeDecision(options: ["A", "B", "C", "D", "E"])

        for _ in 0..<200 {
            let plan = try service.makeDrawPlan(for: decision)
            XCTAssertEqual(plan.frames.last?.text, plan.winner)
            XCTAssertEqual(decision.options[plan.winnerIndex], plan.winner)
        }
    }

    /// Plano segue os parâmetros do protótipo v2: 20 trocas e pausa final com o vencedor.
    func testPlanMatchesV2Parameters() throws {
        let decision = try makeDecision(options: ["A", "B", "C"])
        let plan = try service.makeDrawPlan(for: decision)

        XCTAssertEqual(plan.frames.count, DecisionService.tickCount)
        XCTAssertEqual(plan.frames.last?.duration ?? 0, DecisionService.endPauseDuration, accuracy: 0.0001)
    }

    /// Com duas opções, frames consecutivos devem alternar (nunca repetir a mesma opção).
    func testConsecutiveFramesAreNeverTheSameOption() throws {
        let decision = try makeDecision(options: ["A", "B"])
        let plan = try service.makeDrawPlan(for: decision)

        for (previous, next) in zip(plan.frames, plan.frames.dropFirst()) {
            XCTAssertNotEqual(previous.text, next.text)
        }
    }

    /// As trocas desaceleram: intervalos das trocas (exceto a pausa final) crescem e o fim é mais lento que o início.
    func testAnimationSlowsDown() throws {
        let decision = try makeDecision(options: ["A", "B", "C"])
        let plan = try service.makeDrawPlan(for: decision)

        let spinDurations = Array(plan.frames.dropLast().map(\.duration))
        XCTAssertEqual(spinDurations, spinDurations.sorted())
        XCTAssertLessThan(spinDurations.first ?? 0, spinDurations.last ?? 0)
        // Último intervalo de troca segue a curva (índice TICKS-2) antes da pausa final do vencedor.
        let expectedLastSpin = DecisionService.tickDelay(for: DecisionService.tickCount - 2)
        XCTAssertEqual(spinDurations.last ?? 0, expectedLastSpin, accuracy: 0.0001)
        XCTAssertEqual(spinDurations.first ?? 0, DecisionService.fastestFrameDuration, accuracy: 0.0001)
    }

    /// Em muitas execuções, cada opção deve vencer com frequência aproximada (aleatoriedade justa).
    func testEveryOptionHasRoughlyTheSameChance() throws {
        let decision = try makeDecision(options: ["A", "B", "C"])
        var counts = [String: Int]()
        let draws = 3000

        for _ in 0..<draws {
            let plan = try service.makeDrawPlan(for: decision)
            counts[plan.winner, default: 0] += 1
        }

        for option in decision.options {
            let count = counts[option, default: 0]
            XCTAssertTrue((800...1200).contains(count), "\(option) won \(count) times")
        }
    }
}

/*
 MARK: - Como seria em SwiftUI (equivalente conceitual)

 Estes testes do `DecisionService` não dependem de UIKit/SwiftUI e permanecem válidos em um app
 SwiftUI (o serviço é agnóstico de UI). A reprodução do `DrawPlan` na View pode usar `.task`
 e `Task.sleep` respeitando `frame.duration` (incluindo a pausa final de 300ms).
*/
