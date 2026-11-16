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
/// Foco: garantir propriedades importantes do sorteio/animação, como
/// vencedor consistente com o último frame, desaceleração e comportamento de erro.
final class DecisionServiceTests: XCTestCase {

    // Instância do serviço sob teste.
    private let service = DecisionService()

    /// Helper para criar rapidamente uma decisão válida com as opções informadas.
    private func makeDecision(options: [String]) throws -> Decision {
        var decision = Decision(question: "O que comer?")
        for option in options { try decision.addOption(option) }
        return decision
    }

    /// Sortear com menos de 2 opções deve falhar com `.notEnoughOptions`.
    func testDrawFailsWithFewerThanTwoOptions() throws {
        // Cria decisão com apenas 1 opção (inválida para sorteio).
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
            // Último texto exibido == vencedor.
            XCTAssertEqual(plan.frames.last?.text, plan.winner)
            // Índice do vencedor aponta para a mesma opção na lista.
            XCTAssertEqual(decision.options[plan.winnerIndex], plan.winner)
        }
    }

    /// Com duas opções, frames consecutivos devem alternar (nunca repetir a mesma opção).
    func testConsecutiveFramesAreNeverTheSameOption() throws {
        let decision = try makeDecision(options: ["A", "B"])
        let plan = try service.makeDrawPlan(for: decision)

        // Compara cada frame com o próximo.
        for (previous, next) in zip(plan.frames, plan.frames.dropFirst()) {
            XCTAssertNotEqual(previous.text, next.text)
        }
    }

    /// A animação deve desacelerar: durações não decrescentes e fim mais lento que o início.
    func testAnimationSlowsDown() throws {
        let decision = try makeDecision(options: ["A", "B", "C"])
        let plan = try service.makeDrawPlan(for: decision)

        let durations = plan.frames.map(\.duration)
        // Ordenado de forma crescente (não diminui).
        XCTAssertEqual(durations, durations.sorted())
        // Último mais lento que o primeiro.
        XCTAssertLessThan(durations.first ?? 0, durations.last ?? 0)
    }

    /// Em muitas execuções, cada opção deve vencer com frequência aproximada (aleatoriedade justa).
    /// Usa tolerância ampla para evitar falsos negativos por variação estatística.
    func testEveryOptionHasRoughlyTheSameChance() throws {
        let decision = try makeDecision(options: ["A", "B", "C"])
        var counts = [String: Int]()
        let draws = 3000

        for _ in 0..<draws {
            let plan = try service.makeDrawPlan(for: decision)
            counts[plan.winner, default: 0] += 1
        }

        // Esperado ~1000 por opção; intervalo [800, 1200] é tolerância segura.
        for option in decision.options {
            let count = counts[option, default: 0]
            XCTAssertTrue((800...1200).contains(count), "\(option) won \(count) times")
        }
    }
}

/*
 MARK: - Como seria em SwiftUI (equivalente conceitual)

 Assim como os testes do Model, estes testes do `DecisionService` não dependem de UIKit/SwiftUI
 e permanecem os mesmos em um app SwiftUI (o serviço é agnóstico de UI).

 // O que muda em SwiftUI é como a View reproduz o `DrawPlan` (ex.: loop em `.task` com
 // `Task.sleep`), mas as garantias testadas aqui (último frame = vencedor, desaceleração,
 // validação) continuam válidas.

 // Exemplo em Swift Testing (alternativa moderna):
 //
 // import Testing
 // @testable import DecideAi
 //
 // @Suite("DecisionService")
 // struct DecisionServiceSwiftTests {
 //     let service = DecisionService()
 //
 //     @Test func lastFrameIsAlwaysWinner() throws {
 //         var decision = Decision(question: "Q")
 //         try decision.addOption("A"); try decision.addOption("B")
 //         let plan = try service.makeDrawPlan(for: decision)
 //         #expect(plan.frames.last?.text == plan.winner)
 //     }
 // }
*/
