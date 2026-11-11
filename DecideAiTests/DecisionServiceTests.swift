//
//  DecisionServiceTests.swift
//  DecideAi
//
//  Created by Sure Rocha Bezerra on 11/11/26.
//

import XCTest
@testable import DecideAi

final class DecisionServiceTests: XCTestCase {

    private let service = DecisionService()

    private func makeDecision(options: [String]) throws -> Decision {
        var decision = Decision(question: "O que comer?")
        for option in options { try decision.addOption(option) }
        return decision
    }

    func testDrawFailsWithFewerThanTwoOptions() throws {
        let decision = try makeDecision(options: ["Pizza"])
        XCTAssertThrowsError(try service.makeDrawPlan(for: decision)) {
            XCTAssertEqual($0 as? DecisionError, .notEnoughOptions)
        }
    }

    func testLastFrameIsAlwaysTheWinner() throws {
        let decision = try makeDecision(options: ["A", "B", "C", "D", "E"])
        for _ in 0..<200 {
            let plan = try service.makeDrawPlan(for: decision)
            XCTAssertEqual(plan.frames.last?.text, plan.winner)
            XCTAssertEqual(decision.options[plan.winnerIndex], plan.winner)
        }
    }

    func testConsecutiveFramesAreNeverTheSameOption() throws {
        let decision = try makeDecision(options: ["A", "B"])
        let plan = try service.makeDrawPlan(for: decision)
        for (previous, next) in zip(plan.frames, plan.frames.dropFirst()) {
            XCTAssertNotEqual(previous.text, next.text)
        }
    }

    func testAnimationSlowsDown() throws {
        let decision = try makeDecision(options: ["A", "B", "C"])
        let plan = try service.makeDrawPlan(for: decision)
        let durations = plan.frames.map(\.duration)
        XCTAssertEqual(durations, durations.sorted())
        XCTAssertLessThan(durations.first ?? 0, durations.last ?? 0)
    }

    func testEveryOptionHasRoughlyTheSameChance() throws {
        let decision = try makeDecision(options: ["A", "B", "C"])
        var counts = [String: Int]()
        let draws = 3000
        for _ in 0..<draws {
            let plan = try service.makeDrawPlan(for: decision)
            counts[plan.winner, default: 0] += 1
        }
        // Esperado: ~1000 cada. A tolerância de ±200 é larga o bastante
        // para o teste nunca falhar por acaso.
        for option in decision.options {
            let count = counts[option, default: 0]
            XCTAssertTrue((800...1200).contains(count), "\(option) won \(count) times")
        }
    }
}
